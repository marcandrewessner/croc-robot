// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "config.h"
#include "user_pwm_gen.h"

int main() {
  uart_init();
  
  printf("Starting PWM\n");

  user_pwm_set_counter_top(0xEE);
  user_pwm_set_counter_compare(0xE0);
  user_pwm_set_control(USER_PWM_MODE_EDGE_ALIGNED, USER_PWM_CLK_DIV_1);
  
  printf("this is a test to see if the transaction works\n");
  
  user_pwm_set_control(USER_PWM_MODE_DISABLED, USER_PWM_CLK_DIV_1),
  printf("disabled");

  uart_write_flush();
  return 0;
}
