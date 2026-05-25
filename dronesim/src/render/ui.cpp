#include "render_internal.h"

void ui_layout() {
  int buf_w, buf_h;
  glfwGetFramebufferSize(window, &buf_w, &buf_h);
  uistate.rect[0] = {0, 0, buf_w, buf_h};
  uistate.rect[1] = {buf_w - ui.width, 0, ui.width, buf_h};
  uistate.nrect   = 2;
}

void ui_sync() {
  mjui_resize(&ui, &ctx);
  mjr_addAux(ui.auxid, ui.width, ui.maxheight, ui.spacing.samples, &ctx);
  ui_layout();
  mjui_update(-1, -1, &ui, &uistate, &ctx);
}

void fill_uistate(double win_x, double win_y) {
  int win_w, win_h, buf_w, buf_h;
  glfwGetWindowSize(window, &win_w, &win_h);
  glfwGetFramebufferSize(window, &buf_w, &buf_h);
  double ratio = (win_w > 0) ? (double)buf_w / win_w : 1.0;

  uistate.left    = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_LEFT)   == GLFW_PRESS;
  uistate.right   = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_RIGHT)  == GLFW_PRESS;
  uistate.middle  = glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_MIDDLE) == GLFW_PRESS;
  uistate.control = glfwGetKey(window, GLFW_KEY_LEFT_CONTROL)  == GLFW_PRESS ||
                    glfwGetKey(window, GLFW_KEY_RIGHT_CONTROL) == GLFW_PRESS;
  uistate.shift   = glfwGetKey(window, GLFW_KEY_LEFT_SHIFT)    == GLFW_PRESS ||
                    glfwGetKey(window, GLFW_KEY_RIGHT_SHIFT)   == GLFW_PRESS;
  uistate.alt     = glfwGetKey(window, GLFW_KEY_LEFT_ALT)      == GLFW_PRESS ||
                    glfwGetKey(window, GLFW_KEY_RIGHT_ALT)     == GLFW_PRESS;

  double bx = win_x * ratio;
  double by = uistate.rect[0].height - win_y * ratio;

  uistate.dx = bx - uistate.x;
  uistate.dy = by - uistate.y;
  uistate.x  = bx;
  uistate.y  = by;

  uistate.mouserect = mjr_findRect(mju_round(bx), mju_round(by),
                                   uistate.nrect - 1, uistate.rect + 1) + 1;
}
