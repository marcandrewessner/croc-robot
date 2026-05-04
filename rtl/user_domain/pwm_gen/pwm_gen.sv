
module pwm_gen import pwm_gen_pkg::*; #(
  // Default OBI Config 
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig, // SbrObiCfg
  // OBI request type
  parameter type obi_req_t = logic,
  // OBI response type
  parameter type obi_rsp_t = logic,
  // Set the number of generators
  parameter int NrPWMGenerators = 1
) (
  input logic clk_i,
  input logic rst_ni,

  input obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  output logic [NrPWMGenerators-1:0] pwm_signal_o
);

  //////////////////////////////////////////////////
  // Enforce correct use of the PWM generator  //
  //////////////////////////////////////////////////
  initial begin : p_assertations
    assert (NrPWMGenerators>=1) 
      else $fatal(1, "The number of PWM generators must be at least 1");
    assert (NrPWMGenerators<=100)
      else $fatal(1, "The number of PWM generators must be smaller or equal to X"); // TODO
  end


  //////////////////////////////////////////////////
  // Initialize the register file //
  //////////////////////////////////////////////////
  pwm_reg_field_t pwm_reg_bank [NrPWMGenerators];

  pwm_gen_reg #(
    .ObiCfg(ObiCfg),
    .obi_req_t(obi_req_t),
    .obi_rsp_t(obi_rsp_t),
    .NrPWMRegs(NrPWMGenerators)
  ) i_pwm_gen_reg (
    .clk_i,
    .rst_ni,
    .obi_req_i,
    .obi_rsp_o,
    .pwm_reg_bank_o(pwm_reg_bank)
  );


  //////////////////////////////////////////////////
  // Create the pwm generators //
  //////////////////////////////////////////////////
  genvar i;
  generate
    for(i=0; i<NrPWMGenerators; i++) begin : pwm_gen_driver_bank
      pwm_gen_driver #() i_pwm_gen_driver (
        .clk_i,
        .rst_ni,
        .clock_divider_i   (pwm_reg_bank[i].pwm_ctrl.clk_div),
        .mode_i            (pwm_reg_bank[i].pwm_ctrl.mode),
        .counter_top_i     (pwm_reg_bank[i].counter_top),
        .counter_compare_i (pwm_reg_bank[i].counter_compare),
        .signal_o          (pwm_signal_o[i])
      );
    end
  endgenerate

endmodule