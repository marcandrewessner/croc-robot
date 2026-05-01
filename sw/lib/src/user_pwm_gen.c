

#include "user_pwm_gen.h"
#include "util.h"

int user_pwm_set_control(UserPWMMode mode, UserPWMClkDiv clkdiv){
  uint32_t data = clkdiv<<2 | mode;
  *reg32(USER_PWM_ADDRESS, USER_PWM_CONTROL_REG_OFFSET) = data;
  return 0;
}

int user_pwm_set_counter_top(uint32_t counter_top){
  *reg32(USER_PWM_ADDRESS, USER_PWM_CNT_TOP_REG_OFFSET) = counter_top;
}

int user_pwm_set_counter_compare(uint32_t counter_compare){
  *reg32(USER_PWM_ADDRESS, USER_PWM_CNT_COMP_REG_OFFSET) = counter_compare;
}