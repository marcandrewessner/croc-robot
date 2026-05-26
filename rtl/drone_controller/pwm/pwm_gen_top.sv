
module pwm_gen_top import pwm_gen_pkg::*; #(
  // Default OBI Config 
  parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig, // SbrObiCfg
  // Reg2HW
  parameter type reg2hw_t = logic,
  // Set the number of generators
  parameter int NrPWMGenerators = 1
) (
  input logic clk_i,
  input logic rst_ni,

  input reg2hw_t reg2hw,

  output logic [NrPWMGenerators-1:0] pwm_signal_o
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
        .clock_divider_i   ( reg2hw.pwm_ch[i].CONF.CLK_DIV.value ),
        .mode_i            ( reg2hw.pwm_ch[i].CONF.MODE.value ),
        .counter_top_i     ( reg2hw.pwm_ch[i].COUNT_TOP.DATA.value ),
        .counter_compare_i ( reg2hw.pwm_ch[i].COUNT_COMPARE.DATA.value ),
        .signal_o          ( pwm_signal_o[i] )
      );
    end
  endgenerate

endmodule