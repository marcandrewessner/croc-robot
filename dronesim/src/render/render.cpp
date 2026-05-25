#include "render.h"
#include "render_internal.h"

#include <cmath>
#include <cstdio>
#include <cstring>

GLFWwindow* window    = nullptr;
mjvCamera   cam;
mjvOption   opt;
mjvScene    scn;
mjrContext  ctx;
mjUI        ui;
mjuiState   uistate;
mjModel*    s_model   = nullptr;
mjData*     s_data    = nullptr;
bool        button_left   = false;
bool        button_middle = false;
bool        button_right  = false;
double      lastx = 0, lasty = 0;

bool render_init(mjModel* m, mjData* d, ControlParams* params) {
  s_model = m;
  s_data  = d;

  if (!glfwInit()) {
    printf("render: GLFW init failed\n");
    return false;
  }

  window = glfwCreateWindow(1200, 900, "Drone Sim", nullptr, nullptr);
  if (!window) {
    printf("render: GLFW window creation failed\n");
    glfwTerminate();
    return false;
  }

  glfwMakeContextCurrent(window);
  glfwSwapInterval(1);

  glfwSetKeyCallback(window,         cb_keyboard);
  glfwSetMouseButtonCallback(window, cb_mouse_button);
  glfwSetCursorPosCallback(window,   cb_mouse_move);
  glfwSetScrollCallback(window,      cb_scroll);
  glfwSetWindowSizeCallback(window,  cb_window_resize);

  mjv_defaultCamera(&cam);
  mjv_defaultOption(&opt);
  mjv_defaultScene(&scn);
  mjr_defaultContext(&ctx);

  mjv_makeScene(m, &scn, 2000);
  mjr_makeContext(m, &ctx, mjFONTSCALE_150);

  cam.lookat[0] = 0;
  cam.lookat[1] = 0;
  cam.lookat[2] = 0.5;
  cam.distance  = 3.0;
  cam.azimuth   = 90;
  cam.elevation = -20;

  memset(&ui,      0, sizeof(ui));
  memset(&uistate, 0, sizeof(uistate));

  mjuiThemeSpacing compact = mjui_themeSpacing(0);
  compact.total   = 180;
  compact.label   = 80;
  compact.scroll  = 10;
  compact.itemver = 2;
  compact.textver = 2;
  ui.spacing = compact;
  ui.color   = mjui_themeColor(0);
  ui.rectid  = 1;
  ui.auxid   = 0;

  mjuiDef def[] = {
    {mjITEM_SECTION,   "Control",  1, nullptr,          ""},
    {mjITEM_SLIDERNUM, "X ref",    2, &params->x_ref,   "-5 5"},
    {mjITEM_SLIDERNUM, "Y ref",    2, &params->y_ref,   "-5 5"},
    {mjITEM_SLIDERNUM, "Z ref",    2, &params->z_ref,   "0 5"},
    {mjITEM_SLIDERNUM, "Roll",     2, &params->roll,    "-0.5236 0.5236"},
    {mjITEM_SLIDERNUM, "Pitch",    2, &params->pitch,   "-0.5236 0.5236"},
    {mjITEM_SLIDERNUM, "Yaw",      2, &params->yaw,     "-3.1416 3.1416"},
    {mjITEM_END}
  };
  mjui_add(&ui, def);

  ui_sync();

  return true;
}

void render_frame(mjModel* m, mjData* d) {
  int width, height;
  glfwGetFramebufferSize(window, &width, &height);
  mjrRect viewport = {0, 0, width, height};

  mjv_updateScene(m, d, &opt, nullptr, &cam, mjCAT_ALL, &scn);
  mjr_render(viewport, &scn, &ctx);

  mjui_render(&ui, &uistate, &ctx);

  glfwSwapBuffers(window);
  glfwPollEvents();
}

bool render_is_running() {
  return !glfwWindowShouldClose(window);
}

void render_free() {
  mjv_freeScene(&scn);
  mjr_freeContext(&ctx);
  glfwTerminate();
  window = nullptr;
}
