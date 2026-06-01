
package controller_pkg;
  
  /*
  * Define the data parameters
  * for the calculation u = K*(xref-xstate)+u0
  *
  * Dimensions: K(12,4) x(12) u(4)
  * The data is in fixed point Q4.4
  * this means 8 bits per number. It
  * lies in the memory.
  */

  ////////////////////////////
  // DT for control vecs //
  ////////////////////////////

  typedef logic signed [7:0] fxp_s8_q4p4_t;

  typedef fxp_s8_q4p4_t [3:0] fxp_s8_q4p4_vec4_t; // note this is a packed word

  typedef fxp_s8_q4p4_t [11:0] fxp_s8_q4p4_vec12_t;

  localparam fxp_s8_q4p4_t FXP_MAX = 8'sd127;
  localparam fxp_s8_q4p4_t FXP_MIN = -8'sd128;

  // Wrapper for 32bit word to 4 fxp_s8_q4p4 elemnts
  typedef struct packed {
    // Word is layed out as W:[N4][N3][N2][N1]
    fxp_s8_q4p4_t val3;
    fxp_s8_q4p4_t val2;
    fxp_s8_q4p4_t val1;
    fxp_s8_q4p4_t val0;
  } pkdw_fxp_s8_q4p4_t;

  ////////////////////////////
  // Vector calculation //
  ////////////////////////////
  localparam int K_MATRIX_DIM [2] = { 'd4, 'd12 };
  localparam int X_VEC_DIM = 'd12;
  localparam int U_VEC_DIM = 'd4;

  ////////////////////////////
  // Memory //
  ////////////////////////////
  // note this is already in read order, 
  typedef enum logic [2:0] {
    READ_MEM_FSM_STATE_0_RST,
    READ_MEM_FSM_STATE_1_IDLE,
    READ_MEM_FSM_STATE_2_MATRIX_K,   // jump here to update controller 
    READ_MEM_FSM_STATE_3_VEC_U0,
    READ_MEM_FSM_STATE_4_VEC_XREF,   // jump here to update reference
    READ_MEM_FSM_STATE_5_VEC_XSTATE  // jump here to update x state
  } read_mem_fsm_state_e;

 

endpackage 