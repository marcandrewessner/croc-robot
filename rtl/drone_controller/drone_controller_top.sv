
module drone_controller_top import drone_controller_pkg::*; #(
  /// OBI
  parameter obi_pkg::obi_cfg_t MgrObiCfc = obi_pkg::ObiDefaultConfig,
  parameter obi_pkg::obi_cfg_t SbrObiCfg = obi_pkg::ObiDefaultConfig,
  parameter type mgr_obi_req_t = logic,
  parameter type mgr_obi_rsp_t = logic,
  parameter type sbr_obi_req_t = logic,
  parameter type sbr_obi_rsp_t = logic
) (
  input logic clk_i,
  input logic rst_ni,

  /// OBI
  output mgr_obi_req_t mgr_obi_req_o,
  input  mgr_obi_rsp_t mgr_obi_rsp_i,
  input  sbr_obi_req_t sbr_obi_req_i,
  output sbr_obi_rsp_t sbr_obi_rsp_o,

  // Peripheral inout
  output logic [3:0] pwm_out_o
);

  ////////////////////////////
  // Registers //
  ////////////////////////////
  drone_reg2hw_t reg2hw;

  drone_controller_reg #(
    .ID_WIDTH ( SbrObiCfg.IdWidth )
  ) i_drone_controller_reg_top (
    .clk ( clk_i ),
    .rst ( ~rst_ni ),
    // OBI
    .s_obi_req    ( sbr_obi_req_i.req ),
    .s_obi_gnt    ( sbr_obi_rsp_o.gnt ),
    .s_obi_addr   ( sbr_obi_req_i.a.addr - DRONE_REG_OFFSET ),
    .s_obi_we     ( sbr_obi_req_i.a.we ),
    .s_obi_be     ( sbr_obi_req_i.a.be ),
    .s_obi_wdata  ( sbr_obi_req_i.a.wdata ),
    .s_obi_aid    ( sbr_obi_req_i.a.aid ),
    .s_obi_rvalid ( sbr_obi_rsp_o.rvalid ),
    .s_obi_rready ( 1'b1 ),
    .s_obi_rdata  ( sbr_obi_rsp_o.r.rdata ),
    .s_obi_err    ( sbr_obi_rsp_o.r.err ),
    .s_obi_rid    ( sbr_obi_rsp_o.r.rid ),
    // Register interface
    .hwif_out     ( reg2hw )
  );


  ////////////////////////////
  // Hardware Blocks //
  ////////////////////////////

  // PWM Driver
  pwm_gen_top #(
    .ObiCfg          ( SbrObiCfg ),
    .reg2hw_t        ( drone_reg2hw_t ),
    .NrPWMGenerators ( 4 )
  ) i_pwm_gen_top (
    .clk_i,
    .rst_ni,
    .reg2hw       ( reg2hw ),
    .pwm_signal_o ( pwm_out_o )
  );


endmodule