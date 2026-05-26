// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Authors:
// - Philippe Sauter <phsauter@iis.ee.ethz.ch>

module user_domain import user_pkg::*; import croc_pkg::*; #(
  parameter int unsigned GpioCount = 16,
  parameter int unsigned NumExternalIrqs = 4
) (
  input  logic      clk_i,
  input  logic      ref_clk_i,
  input  logic      rst_ni,
  input  logic      testmode_i,

  input  sbr_obi_req_t user_sbr_obi_req_i, // User Sbr (rsp_o), Croc Mgr (req_i)
  output sbr_obi_rsp_t user_sbr_obi_rsp_o,

  output mgr_obi_req_t user_mgr_obi_req_o, // User Mgr (req_o), Croc Sbr (rsp_i)
  input  mgr_obi_rsp_t user_mgr_obi_rsp_i,

  input  logic [      GpioCount-1:0] gpio_in_sync_i, // synchronized GPIO inputs
  output logic [NumExternalIrqs-1:0] interrupts_o    // interrupts to core
);

  // Output the interrupts
  assign interrupts_o = '0;

  ////////////////////////////
  // Drone Controller //
  ////////////////////////////
  drone_controller_top #(
    .MgrObiCfc ( MgrObiCfg ),
    .SbrObiCfg ( SbrObiCfg ),
    .mgr_obi_req_t ( mgr_obi_req_t ),
    .mgr_obi_rsp_t ( mgr_obi_rsp_t ),
    .sbr_obi_req_t ( sbr_obi_req_t ),
    .sbr_obi_rsp_t ( sbr_obi_rsp_t )
  ) i_drone_controller_top (
    .clk_i,
    .rst_ni,
    /// OBI
    .mgr_obi_req_o ( user_mgr_obi_req_o ),
    .mgr_obi_rsp_i ( user_mgr_obi_rsp_i ),
    .sbr_obi_req_i ( user_sbr_obi_req_i ),
    .sbr_obi_rsp_o ( user_sbr_obi_rsp_o ),
    // Signals of peripherals
    .pwm_out_o ( )
  );

endmodule
