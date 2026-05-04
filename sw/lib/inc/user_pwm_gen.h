//
// Library used to control the pwm generator
//

// TODOs
// * implement different pwm adressers
// * (evtl) implement helper functions for percentage


#pragma once

#include <stdint.h>
#include "util.h"


#define USER_PWM_ADDRESS               0x20000000
#define USER_PWM_CONTROL_REG_OFFSET    (0x0 << 2)
#define USER_PWM_CNT_TOP_REG_OFFSET    (0x1 << 2)
#define USER_PWM_CNT_COMP_REG_OFFSET   (0x2 << 2)


typedef enum {
  USER_PWM_MODE_DISABLED        = 0b00,
  USER_PWM_MODE_EDGE_ALIGNED    = 0b01,
  USER_PWM_MODE_CENTER_ALIGNED  = 0b10,
  USER_PWM_MODE_RESERVED        = 0b11
} UserPWMMode;

typedef enum {
  USER_PWM_CLK_DIV_1 = 0b00,
  USER_PWM_CLK_DIV_2 = 0b01,
  USER_PWM_CLK_DIV_4 = 0b10,
  USER_PWM_CLK_DIV_8 = 0b11
} UserPWMClkDiv;


int user_pwm_set_control(uint32_t instance, UserPWMMode mode, UserPWMClkDiv clkdiv);
int user_pwm_set_counter_top(uint32_t instance, uint32_t counter_top);
int user_pwm_set_counter_compare(uint32_t instance, uint32_t counter_compare);