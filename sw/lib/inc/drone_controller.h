#ifndef __DRONE_CONTROLLER_H__
#define __DRONE_CONTROLLER_H__

#include "drone_controller_reg.h"


#define DRONE_CONTROLLER_REG_ADDRESS 0x20000000u

//////////////////////
// PWM //
//////////////////////

#define PWM_CHANN_MODE_MASK    PWM_CHANNEL_T__CONF__MODE_bm
#define PWM_CHANN_MODE_BP      PWM_CHANNEL_T__CONF__MODE_bp
#define PWM_CHANN_CLK_DIV_MASK PWM_CHANNEL_T__CONF__CLK_DIV_bm
#define PWM_CHANN_CLK_DIV_BP   PWM_CHANNEL_T__CONF__CLK_DIV_bp

#define CONTROLLER_CMD_RUN     CONTROLLER_T__CMD__RUN_CALC_bm

typedef enum {
  PWM_MODE_DISABLED       = 0b00,
  PWM_MODE_EDGE_ALIGNED   = 0b01,
  PWM_MODE_CENTER_ALIGNED = 0b10,
  PWM_MODE_RESERVED       = 0b11
} pwm_mode_e;

typedef enum {
  PWM_CLK_DIV_1 = 0b00,
  PWM_CLK_DIV_2 = 0b01,
  PWM_CLK_DIV_4 = 0b10,
  PWM_CLK_DIV_8 = 0b11
} pwm_clk_div_e;

// Define the register location
#define DRONE_CONTROLLER_REG \
  ((volatile drone_controller_reg_t * const) DRONE_CONTROLLER_REG_ADDRESS)

#endif