#include "render_internal.h"

void cb_keyboard(GLFWwindow* /*win*/, int key, int /*sc*/, int act, int /*mod*/) {
  if (act != GLFW_PRESS) return;
  if (key == GLFW_KEY_BACKSPACE) mj_resetData(s_model, s_data);
  if (key == GLFW_KEY_ESCAPE)    glfwSetWindowShouldClose(window, GLFW_TRUE);
}

void cb_mouse_button(GLFWwindow* win, int btn, int act, int /*mod*/) {
  double x, y;
  glfwGetCursorPos(win, &x, &y);
  fill_uistate(x, y);

  bool in_ui = (uistate.mouserect == ui.rectid);

  if (act == GLFW_PRESS) {
    uistate.type   = mjEVENT_PRESS;
    uistate.button = (btn == GLFW_MOUSE_BUTTON_LEFT)   ? mjBUTTON_LEFT  :
                     (btn == GLFW_MOUSE_BUTTON_RIGHT)  ? mjBUTTON_RIGHT :
                                                          mjBUTTON_MIDDLE;
    if (uistate.mouserect) {
      uistate.dragbutton = uistate.button;
      uistate.dragrect   = uistate.mouserect;
    }

    if (!in_ui) {
      button_left   = glfwGetMouseButton(win, GLFW_MOUSE_BUTTON_LEFT)   == GLFW_PRESS;
      button_middle = glfwGetMouseButton(win, GLFW_MOUSE_BUTTON_MIDDLE) == GLFW_PRESS;
      button_right  = glfwGetMouseButton(win, GLFW_MOUSE_BUTTON_RIGHT)  == GLFW_PRESS;
      lastx = x;
      lasty = y;
    }
  } else {
    uistate.type  = mjEVENT_RELEASE;
    button_left   = false;
    button_middle = false;
    button_right  = false;
  }

  if (in_ui || uistate.dragrect == ui.rectid)
    mjui_event(&ui, &uistate, &ctx);

  if (uistate.type == mjEVENT_RELEASE) {
    uistate.dragrect   = 0;
    uistate.dragbutton = 0;
  }
}

void cb_mouse_move(GLFWwindow* win, double xpos, double ypos) {
  fill_uistate(xpos, ypos);
  uistate.type = mjEVENT_MOVE;

  if (uistate.dragrect == ui.rectid) {
    mjui_event(&ui, &uistate, &ctx);
    lastx = xpos;
    lasty = ypos;
    return;
  }

  if (!button_left && !button_middle && !button_right) {
    lastx = xpos;
    lasty = ypos;
    return;
  }

  double dx = xpos - lastx;
  double dy = ypos - lasty;
  lastx = xpos;
  lasty = ypos;

  int width, height;
  glfwGetWindowSize(win, &width, &height);

  mjtMouse action;
  if      (button_right)  action = mjMOUSE_MOVE_V;
  else if (button_middle) action = mjMOUSE_MOVE_H;
  else                    action = mjMOUSE_ROTATE_V;

  mjv_moveCamera(s_model, action, dx / height, dy / height, &scn, &cam);
}

void cb_scroll(GLFWwindow* win, double /*dx*/, double dy) {
  double x, y;
  glfwGetCursorPos(win, &x, &y);
  fill_uistate(x, y);
  uistate.type = mjEVENT_SCROLL;
  uistate.sy   = dy;

  if (uistate.mouserect == ui.rectid)
    mjui_event(&ui, &uistate, &ctx);
  else
    mjv_moveCamera(s_model, mjMOUSE_ZOOM, 0, -0.05 * dy, &scn, &cam);
}

void cb_window_resize(GLFWwindow* /*win*/, int /*w*/, int /*h*/) {
  ui_sync();
}
