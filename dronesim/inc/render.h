#pragma once

#include <mujoco/mujoco.h>
#include "control.h"

// Initializes GLFW window and MuJoCo visualization context.
// Returns false on failure.
bool render_init(mjModel* m, mjData* d, ControlParams* params);

// Renders one frame and polls input events.
// Call once per simulation loop iteration.
void render_frame(mjModel* m, mjData* d);

// Returns true while the window is open.
bool render_is_running();

// Frees all visualization resources and closes the window.
void render_free();
