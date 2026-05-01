
module pwm_gen import pwm_gen_pkg::*; #(
  // Default OBI Config 
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig, // SbrObiCfg
  // OBI request type
  parameter type obi_req_t = logic,
  // OBI response type
  parameter type obi_rsp_t = logic,
  // Set the number of generators TODO
  parameter int NrPWMGenerators = 1
) (
  input logic clk_i,
  input logic rst_ni,

  input obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  output logic [NrPWMGenerators-1:0] pwm_signal_o
);

  //////////////////////////////////////////////////
  // Initialize the register file //
  //////////////////////////////////////////////////
  pwm_reg_field_t pwm_reg;

  pwm_gen_reg #(
    .ObiCfg(ObiCfg),
    .obi_req_t(obi_req_t),
    .obi_rsp_t(obi_rsp_t)
  ) i_pwm_gen_reg (
    .clk_i,
    .rst_ni,
    .obi_req_i,
    .obi_rsp_o,
    .pwm_reg_o(pwm_reg)
  );


  //////////////////////////////////////////////////
  // Create the pwm generators //
  //////////////////////////////////////////////////
  pwm_gen_driver #() i_pwm_gen_driver (
    .clk_i,
    .rst_ni,
    .clock_divider_i(pwm_reg.pwm_ctrl.clk_div),
    .mode_i(pwm_reg.pwm_ctrl.mode),
    .counter_top_i(pwm_reg.counter_top),
    .counter_compare_i(pwm_reg.counter_compare),
    .signal_o(pwm_signal_o)
  );

endmodule