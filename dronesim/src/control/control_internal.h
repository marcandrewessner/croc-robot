#pragma once

#include "control.h"

#include <Eigen/Dense>

// Model extraction
static constexpr int thrust_idx_length = 4;
extern int drone_body_idx;
extern int thrust_idx[thrust_idx_length];
extern mjtNum max_thrust;
extern int imu_gyro_idx;
extern int imu_quat_idx;

// System ID matrices (populated by control_system_id)
static constexpr int kNs   = 12;
static constexpr int kNu   = 4;
static constexpr int kNout = 13;
extern Eigen::Matrix<mjtNum, kNs,   kNs>   sysid_A;
extern Eigen::Matrix<mjtNum, kNs,   kNu>   sysid_B;
extern Eigen::Matrix<mjtNum, kNout, kNs>   sysid_C;
extern Eigen::Matrix<mjtNum, kNout, kNu>   sysid_D;

// lqr.cpp
Eigen::MatrixXd lqr_dare(
  const Eigen::MatrixXd& A,
  const Eigen::MatrixXd& B,
  const Eigen::MatrixXd& Q,
  const Eigen::MatrixXd& R,
  int max_iter = 1000, double tol = 1e-10
);

// hover.cpp
void control_update_hover(mjModel* m, mjData* d, const ControlParams* params);
void inner_loop_stabilization(mjModel* m, mjData* d, const ControlParams *params);
void derive_inner_loop_controller(mjModel* m, mjData* d);