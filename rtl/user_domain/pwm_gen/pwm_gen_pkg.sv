

package pwm_gen_pkg;

  //////////////////////////////////////////////////
  // Define Operation Modes of the Generator //
  //////////////////////////////////////////////////

  typedef enum logic [1:0] { 
    PWM_MODE_DISABLED        = 2'b00,
    PWM_MODE_EDGE_ALIGNED    = 2'b01,
    PWM_MODE_CENTER_ALIGNED  = 2'b10,
    PWM_MODE_RESERVED        = 2'b11
  } pwm_mode_e;

  typedef enum logic [1:0] { 
    CLK_DIV_1 = 2'b00,
    CLK_DIV_2 = 2'b01,
    CLK_DIV_4 = 2'b10,
    CLK_DIV_8 = 2'b11
  } pwm_clk_div_e;

  // Define how long one counter is.
  // With RISC-V 32 the counter is one word long.
  localparam int CounterBits = 32;

  //////////////////////////////////////////////////
  // Register Data Types //
  //////////////////////////////////////////////////

  typedef struct packed {
    logic unused7;
    logic unused6;
    logic unused5;
    logic unused4;
    logic [1:0] clk_div; // Clock division mode (pwm_clk_div_e) 
    logic [1:0] mode;    // PWM Mode (pwm_mode_e)
  } pwm_ctrl_bits_t;

  //////////////////////////////////////////////////
  // Register Types //
  //////////////////////////////////////////////////

  typedef struct packed {
    pwm_ctrl_bits_t pwm_ctrl; // Control register
    logic [CounterBits-1:0] counter_top;
    logic [CounterBits-1:0] counter_compare;
  } pwm_reg_field_t;

  // Default reset value
  localparam pwm_reg_field_t PWMRegResetVal = '{
    pwm_ctrl        : {4'b0, CLK_DIV_1, PWM_MODE_DISABLED},
    counter_top     : '0,
    counter_compare : '0
  };

  //////////////////////////////////////////////////
  // OBI Adress Offsets //
  //////////////////////////////////////////////////
  
  // The adresses are 4 bytes aligned => (4bytes = 1word = 32bits)
  // So the first two bits are useless
  localparam int AddressBits = 8;

  localparam bit [AddressBits-1:0] RegAddrControl = 'h00;
  localparam bit [AddressBits-1:0] RegAddrTop     = 'h04;
  localparam bit [AddressBits-1:0] RegAddrCompare = 'h08;

endpackage