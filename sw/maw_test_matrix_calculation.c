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


// Define the location of the controllers
fxp_s8_q4p4_t K_matrix[K_MATRIX_ROW*K_MATRIX_COL];
fxp_s8_q4p4_t U0_vec[U_VEC_DIM];
fxp_s8_q4p4_t XREF_vec[X_VEC_DIM];
fxp_s8_q4p4_t XSTATE_vec[X_VEC_DIM];

int main() {
  uart_init();
  
  printf("Starting PWM\n");

  DRONE_CONTROLLER_REG->pwm_ch[0].COUNT_TOP = 10;
  DRONE_CONTROLLER_REG->pwm_ch[0].COUNT_COMPARE = 5;
  DRONE_CONTROLLER_REG->pwm_ch[0].CONF = PWM_MODE_EDGE_ALIGNED<<PWM_CHANN_MODE_BP;

  // Prepare the controller matrix
  for(int i=0; i<4*12; i++)
    K_matrix[i] = i;
  
  for(int i=0; i<4; i++)
    U0_vec[i] = i;

  for(int i=0; i<12; i++){
    XREF_vec[i]   = i;
    XSTATE_vec[i] = i*2;
  }
  
  // Find the addresses
  uint32_t K_matrix_addr   = (uint32_t) &K_matrix;
  uint32_t U0_vec_addr     = (uint32_t) &U0_vec;
  uint32_t XREF_vec_addr   = (uint32_t) &XREF_vec;
  uint32_t XSTATE_vec_addr = (uint32_t) &XSTATE_vec;
  printf("K_matrix is at: %x\n",   K_matrix_addr);
  printf("U0 vec is at: %x\n",     U0_vec_addr);
  printf("XREF vec is at: %x\n",   XREF_vec_addr);
  printf("XSTATE vec is at: %x\n", XSTATE_vec_addr);

  // Now lets configure the drone Controller to know where to find the K_matrix and read in
  DRONE_CONTROLLER_REG->controller.K_MATRIX  = K_matrix_addr;
  DRONE_CONTROLLER_REG->controller.U0_VEC    = U0_vec_addr;
  DRONE_CONTROLLER_REG->controller.X_REF_VEC = XREF_vec_addr;
  DRONE_CONTROLLER_REG->controller.X_IN_VEC  = XSTATE_vec_addr;
  DRONE_CONTROLLER_REG->controller.CMD = CONTROLLER_CMD_UDPATE_CONTROLLER;

  for(volatile int i=0; i<10000; i++);

  DRONE_CONTROLLER_REG->pwm_ch[0].CONF = PWM_MODE_DISABLED<<PWM_CHANN_MODE_BP;

  uart_write_flush();
  return 0;
}
