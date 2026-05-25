#pragma once

#include <GLFW/glfw3.h>
#include <mujoco/mujoco.h>
#include <mujoco/mjui.h>

// Shared render state
extern GLFWwindow* window;
extern mjvCamera   cam;
extern mjvOption   opt;
extern mjvScene    scn;
extern mjrContext  ctx;
extern mjUI        ui;
extern mjuiState   uistate;
extern mjModel*    s_model;
extern mjData*     s_data;
extern bool        button_left;
extern bool        button_middle;
extern bool        button_right;
extern double      lastx, lasty;

// ui.cpp
void ui_layout();
void ui_sync();
void fill_uistate(double win_x, double win_y);

// callbacks.cpp
void cb_keyboard(GLFWwindow* win, int key, int sc, int act, int mod);
void cb_mouse_button(GLFWwindow* win, int btn, int act, int mod);
void cb_mouse_move(GLFWwindow* win, double xpos, double ypos);
void cb_scroll(GLFWwindow* win, double dx, double dy);
void cb_window_resize(GLFWwindow* win, int w, int h);
