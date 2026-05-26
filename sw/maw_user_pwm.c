// Copyright (c) 2024 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

#include "uart.h"
#include "print.h"
#include "config.h"
#include "drone_controller.h"

int main() {
  uart_init();
  
  printf("Starting PWM\n");

  DRONE_CONTROLLER_REG->pwm_ch[0].COUNT_TOP = 10;
  DRONE_CONTROLLER_REG->pwm_ch[0].COUNT_COMPARE = 5;
  DRONE_CONTROLLER_REG->pwm_ch[0].CONF = PWM_MODE_EDGE_ALIGNED<<PWM_CHANN_MODE_BP;

  for(volatile int i=0; i<10000; i++);

  DRONE_CONTROLLER_REG->pwm_ch[0].CONF = PWM_MODE_DISABLED<<PWM_CHANN_MODE_BP;

  uart_write_flush();
  return 0;
}
