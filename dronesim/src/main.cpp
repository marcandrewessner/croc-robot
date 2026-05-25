
#include <cstdio>
#include <mujoco/mujoco.h>

#include "render.h"
#include "control.h"

int main() {
  printf("====== STARTING THE DRONE SIMULATION ======\n");

  ////////////////////////////////
  // load model and mk data //
  ////////////////////////////////

  char err_msg[1000];
  const char *model_file = "assets/mujoco_menagerie/skydio_x2/scene.xml";
  
  mjModel* model = mj_loadXML(model_file, nullptr, err_msg, sizeof(err_msg));
  if (!model) {
    printf("Load model error: %s\n", err_msg);
    return 1;
  }
  
  mjData* data = mj_makeData(model);

  ////////////////////////////////
  // set to hovering //
  ////////////////////////////////

  mj_resetDataKeyframe(model, data, mj_name2id(model, mjOBJ_KEY, "hover"));
  mj_forward(model, data);  // compute xpos/xquat from qpos so first control step sees correct state

  ////////////////////////////////
  // init renderer and control //
  ////////////////////////////////

  ControlParams params = {.z_ref = 1.0};

  render_init(model, data, &params);

  printf("timestep: %f\n", model->opt.timestep);
  control_system_id(model, data);
  control_init(model, data);

  ////////////////////////////////
  // sim loop //
  ////////////////////////////////

  while (render_is_running()) {
    mjtNum sim_start = data->time;
    while (data->time - sim_start < 1.0 / 60.0) {
      control_update(model, data, &params);
      mj_step(model, data);
    }

    render_frame(model, data);
  }

  ////////////////////////////////
  // free //
  ////////////////////////////////

  render_free();
  mj_deleteData(data);
  mj_deleteModel(model);

  return 0;
}
