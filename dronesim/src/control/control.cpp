#include "control_internal.h"

#include <string>

int drone_body_idx;
int thrust_idx[thrust_idx_length];
mjtNum max_thrust;
int imu_gyro_idx;
int imu_quat_idx;

int control_init(mjModel* m, mjData* d) {
  drone_body_idx = mj_name2id(m, mjOBJ_BODY, "x2");
  imu_gyro_idx   = mj_name2id(m, mjOBJ_SENSOR, "body_gyro");
  imu_quat_idx   = mj_name2id(m, mjOBJ_SENSOR, "body_quat");

  for (int i = 0; i < thrust_idx_length; i++) {
    std::string name = "thrust" + std::to_string(i + 1);
    thrust_idx[i] = mj_name2id(m, mjOBJ_ACTUATOR, name.c_str());
  }

  max_thrust = m->actuator_ctrlrange[1];

  // Calculate the controllers
  derive_inner_loop_controller(m,d);

  return 0;
}

void control_update(mjModel* m, mjData* d, const ControlParams* params) {
  control_update_hover(m, d, params);
}
