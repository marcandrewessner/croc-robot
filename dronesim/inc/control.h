#pragma once

#include <mujoco/mujoco.h>

struct ControlParams {
  mjtNum x_ref;
  mjtNum y_ref;
  mjtNum z_ref;
  mjtNum roll;
  mjtNum pitch;
  mjtNum yaw;
};

// Runs finite-difference system identification and saves the result to disk.
// Returns 0 on success, 1 on error.
int control_system_id(mjModel* m, mjData* d);

// Called once after the model and data are created. Loads the system from disk.
// Returns 0 on success, 1 on error (e.g. system file not found).
int control_init(mjModel* m, mjData* d);

// Called every physics timestep before mj_step.
// Write your control logic here — sets data->ctrl[].
void control_update(mjModel* m, mjData* d, const ControlParams* params);
