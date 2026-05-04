

`include "common_cells/registers.svh"

module pwm_gen_driver import pwm_gen_pkg::*; #(

) (
  input logic clk_i,
  input logic rst_ni,

  input pwm_clk_div_e clock_divider_i,
  input pwm_mode_e mode_i,

  input logic [CounterBits-1:0] counter_top_i,
  input logic [CounterBits-1:0] counter_compare_i,

  // The PWM signal at output
  output logic signal_o
);

  //////////////////////////////////////////////////
  // Counter Logic //
  //////////////////////////////////////////////////

  logic compare_is_bigger;
  logic counter_at_top;

  logic pos_increment_d, pos_increment_q;
  logic [CounterBits-1:0] counter_d, counter_q;

  always_comb begin : pwm_counter
    // Set the default values
    counter_d = '0;
    pos_increment_d = 1;
    // Run logic
    case (mode_i)
      PWM_MODE_DISABLED: ;
      PWM_MODE_EDGE_ALIGNED: begin
        counter_d = counter_at_top ? '0 : counter_q + 1;
      end
      PWM_MODE_CENTER_ALIGNED: ; //TODO
    endcase
  end

  assign counter_at_top = (counter_q >= counter_top_i);
  assign compare_is_bigger = (counter_q >= counter_compare_i);

  // Standard flip flop
  `FF(counter_q, counter_d, '0, clk_i, rst_ni)
  `FF(pos_increment_q, pos_increment_d, 1'b1, clk_i, rst_ni)

  //////////////////////////////////////////////////
  // Output signal conditioning //
  //////////////////////////////////////////////////
  assign signal_o = ~compare_is_bigger && (mode_i!=PWM_MODE_DISABLED);

endmodule 