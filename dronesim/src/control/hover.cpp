#include "control_internal.h"

#include <iostream>
#include <cmath>
#include <cstdio>
#include <Eigen/Dense>


// Quantize to QA.B fixed-point format (signed, A+B total bits)
template<int A = 4, int B = 4, typename Derived>
inline void quant(Eigen::MatrixBase<Derived>& m){
  constexpr mjtNum scale = mjtNum(1LL << B);
  constexpr mjtNum i_max = mjtNum( (1LL << (A + B - 1)) - 1);
  constexpr mjtNum i_min = mjtNum(-(1LL << (A + B - 1)));
  m = (m * scale).array().round().max(i_min).min(i_max) / scale;
}


// Controller
static constexpr mjtNum u0_thrust = 3.2495625;
static Eigen::Matrix<mjtNum, 4, 12> K;
static Eigen::Matrix<mjtNum, 4, 12> Kquant;


void control_update_hover(mjModel* m, mjData* d, const ControlParams* params) {
  // the thrust is currently PID controlled lets leave this as is
  inner_loop_stabilization(m, d, params);
}

// Now we want to stabilize the system
// with the controller input e
// e = [Thrust roll pitch yaw droll dpitch dyaw]
// with the controller output u
// u  = [t1 t2 t3 t4]
// note that the controller does u = Ke
// and based on roll pitch yaw characteristics
void inner_loop_stabilization(mjModel* m, mjData* d, const ControlParams *params) {
  // Calculate the sensor data into usable data
  const mjtNum* q    = &d->sensordata[m->sensor_adr[imu_quat_idx]]; // w x y z
  mjtNum roll  = std::atan2(2*(q[0]*q[1] + q[2]*q[3]), 1 - 2*(q[1]*q[1] + q[2]*q[2]));
  mjtNum pitch = std::asin (2*(q[0]*q[2] - q[3]*q[1]));
  mjtNum yaw   = std::atan2(2*(q[0]*q[3] + q[1]*q[2]), 1 - 2*(q[2]*q[2] + q[3]*q[3]));

  const mjtNum* gyro = &d->sensordata[m->sensor_adr[imu_gyro_idx]]; // body-frame wx wy wz

  const mjtNum* pos    = d->qpos;      // world x y z
  const mjtNum* linvel = d->qvel;      // world vx vy vz

  // Now build up the state and quantize
  Eigen::Vector<mjtNum, 12> x, xref;
  x    << pos[0], pos[1], pos[2], roll, pitch, yaw, linvel[0], linvel[1], linvel[2], gyro[0], gyro[1], gyro[2];
  xref << params->x_ref, params->y_ref, params->z_ref, params->roll, params->pitch, params->yaw, 0, 0, 0, 0, 0, 0;
  quant(x);
  quant(xref);

  // Claculate u = u0 + Kxerr
  Eigen::Vector<mjtNum, 12> xerr = xref - x;
  quant(xerr);

  Eigen::Vector<mjtNum, 4> u = Kquant * xerr;
  quant(u);
  u += Eigen::Vector<mjtNum, 4>::Constant(u0_thrust);
  quant(u);

  // Now we apply the thrust
  for(int i=0; i<thrust_idx_length; i++)
    d->ctrl[thrust_idx[i]] = u[i];
}


// Note for now we use full state space
// thus the controller can directly control position for the rest
// as well
void derive_inner_loop_controller(mjModel* m, mjData* d){

  // Now for LQR we define Q and R
  auto Q = (
    Eigen::Vector<mjtNum, 12>() << 3, 3, 3, 1, 1, 1, 1, 1, 1, 1, 1, 1
  ).finished().asDiagonal();

  auto R = Eigen::Matrix<mjtNum, 4, 4>::Identity();

  // Now calculate LQR
  K = lqr_dare(sysid_A, sysid_B, Q, R);

  // Create a quantized copy
  Kquant = K;
  quant(Kquant);

  // Print the controller K
  std::cout << "K (" << K.rows() << "x" << K.cols() << "):\n" << K << "\n";
  std::cout << "Kquant (" << Kquant.rows() << "x" << Kquant.cols() << "):\n" << Kquant << "\n";
}