

`include "common_cells/registers.svh"

module controller_top import controller_pkg::*; #(
  parameter type reg2hw_t = logic,
  /// OBI
  parameter type mgr_obi_req_t = logic,
  parameter type mgr_obi_rsp_t = logic
) (
  input logic clk_i,
  input logic rst_ni,
  /// OBI
  output mgr_obi_req_t mgr_obi_req_o,
  input  mgr_obi_rsp_t mgr_obi_rsp_i,
  // register interface
  input reg2hw_t reg2hw
);

  // The goal here is to calculate
  // u = K(xref-xstate) + u0

  // for the drone controller the dimensions look
  // as following:
  // Matrix      K 4x12
  // State Vec   X 12x1
  // Control Vec U 4x1

  ////////////////////////////
  // Vector Variables //
  ////////////////////////////

  // Read and cache controller matrix K
  fxp_s8_q4p4_vec12_t matk_d [4];
  fxp_s8_q4p4_vec12_t matk_q [4];

  // Read in xref, xstate and u0
  fxp_s8_q4p4_vec12_t xref_d, xref_q;
  fxp_s8_q4p4_vec12_t xstate_d, xstate_q;
  fxp_s8_q4p4_vec4_t u0_d, u0_q;

  // Define FF q<=d
  `FF(matk_q, matk_d, '{default: '0}, clk_i, rst_ni)
  `FF(xref_q, xref_d, '0, clk_i, rst_ni)
  `FF(xstate_q, xstate_d, '0, clk_i, rst_ni)
  `FF(u0_q, u0_d, '0, clk_i, rst_ni)

  ////////////////////////////
  // Vec calculations //
  ////////////////////////////

  // TODO calculate the controller


  ////////////////////////////
  // Memory Interface //
  ////////////////////////////
  logic        request_sram_read, request_sram_write, request_sram_done;
  logic        sram_wrequest_word, sram_rvalid_word;
  logic [31:0] sram_addr_word;
  logic [31:0] sram_rdata_word;
  logic [31:0] sram_wdata_word;
  logic [31:0] sram_n_words;
  logic [31:0] sram_data_word_number;

  controller_memory_interface #(
    .mgr_obi_req_t ( mgr_obi_req_t ),
    .mgr_obi_rsp_t ( mgr_obi_rsp_t )
  ) i_controller_memory_interface (
    .clk_i,
    .rst_ni,
    /// OBI
    .mgr_obi_req_o       ( mgr_obi_req_o      ),
    .mgr_obi_rsp_i       ( mgr_obi_rsp_i      ),
    // Read Control
    .request_read_i      ( request_sram_read  ),
    .data_word_o         ( sram_rdata_word    ),
    .data_word_valid_o   ( sram_rvalid_word   ),
    // Write Control
    .request_write_i     ( request_sram_write ),
    .data_word_i         ( sram_wdata_word    ),
    .data_word_request_o ( sram_wrequest_word ),
    // RW Control
    .addr_word_i         ( sram_addr_word     ),
    .request_done_o      ( request_sram_done  ),
    .data_word_number_o  ( sram_data_word_number ),
    .n_words_i           ( sram_n_words ),
    .err_o               ( )
  );

  ////////////////////////////
  // Reader FSM //
  ////////////////////////////
  read_mem_fsm_state_e rd_fsm_state_d, rd_fsm_state_q;

  // rd_ptr_offset: _c = combinational working wire (RW within always_comb)
  //               _d/_q = FF pair; _d is write-only, driven from _c at block end
  logic [31:0] rd_ptr_offset_c, rd_ptr_offset_d, rd_ptr_offset_q;

  always_comb begin : read_memory_fsm

    // Drive the memory interface here
    request_sram_read  = 1'b0;
    request_sram_write = 1'b0;
    sram_addr_word     = '0;

    // Latch fsm state
    rd_fsm_state_d  = rd_fsm_state_q;
    rd_ptr_offset_c = rd_ptr_offset_q;

    // Latch vector variables
    matk_d   = matk_q;
    xref_d   = xref_q;
    xstate_d = xstate_q;
    u0_d     = u0_q;

    unique case (rd_fsm_state_q)
      // Initial starting point
      READ_MEM_FSM_STATE_0_RST, READ_MEM_FSM_STATE_1_IDLE: begin
        rd_ptr_offset_c = '0;
        // Initiate update full controller
        if (reg2hw.controller.CMD.UPDATE_CONTROLLER.value)
          rd_fsm_state_d = READ_MEM_FSM_STATE_2_MATRIX_K;
        // Initiate update reference
        if (reg2hw.controller.CMD.UPDATE_CONTROLLER_REFERENCE.value)
          rd_fsm_state_d = READ_MEM_FSM_STATE_4_VEC_XREF;
        // Initiate update state
        if (reg2hw.controller.CMD.UPDATE_CONTROLLER_STATE.value)
          rd_fsm_state_d = READ_MEM_FSM_STATE_5_VEC_XSTATE;
      end
      READ_MEM_FSM_STATE_2_MATRIX_K: begin
        // Request the read
        request_sram_read = 1'b1;
        sram_n_words      = K_MATRIX_DIM[0]*K_MATRIX_DIM[1]/4;
        sram_addr_word    = reg2hw.controller.K_MATRIX.POINTER.value;
        // If we get an input
        if(sram_rvalid_word) begin
          int mat_row, mat_col;
          pkdw_fxp_s8_q4p4_t pkd_data;
          mat_row = sram_data_word_number*4 / K_MATRIX_DIM[1];
          mat_col = sram_data_word_number*4 - mat_row*K_MATRIX_DIM[1];
          // Now filll in the matrix
          pkd_data = sram_rdata_word;
          // Unpack for matrix
          matk_d[mat_row][mat_col+0] = pkd_data.val0;
          matk_d[mat_row][mat_col+1] = pkd_data.val1;
          matk_d[mat_row][mat_col+2] = pkd_data.val2;
          matk_d[mat_row][mat_col+3] = pkd_data.val3;
        end
        // If end move to next state
        if(request_sram_done)
          rd_fsm_state_d = READ_MEM_FSM_STATE_3_VEC_U0;
      end
      READ_MEM_FSM_STATE_3_VEC_U0: begin
        // Request the read
        request_sram_read = 1'b1;
        sram_n_words      = U_VEC_DIM/4;
        sram_addr_word    = reg2hw.controller.U0_VEC.POINTER.value;
        // Once we get the input
        if(sram_rvalid_word) begin
          pkdw_fxp_s8_q4p4_t pkd_data;
          pkd_data = sram_rdata_word;
          u0_d[sram_data_word_number*4+0] = pkd_data.val0;
          u0_d[sram_data_word_number*4+1] = pkd_data.val1;
          u0_d[sram_data_word_number*4+2] = pkd_data.val2;
          u0_d[sram_data_word_number*4+3] = pkd_data.val3;
        end
         // If end move to next state
        if(request_sram_done)
          rd_fsm_state_d = READ_MEM_FSM_STATE_4_VEC_XREF;
      end
      READ_MEM_FSM_STATE_4_VEC_XREF: begin
        // Request the read
        request_sram_read = 1'b1;
        sram_n_words      = X_VEC_DIM/4;
        sram_addr_word    = reg2hw.controller.X_REF_VEC.POINTER.value;
        // Once we get the input
        if(sram_rvalid_word) begin
          pkdw_fxp_s8_q4p4_t pkd_data;
          pkd_data = sram_rdata_word;
          xref_d[sram_data_word_number*4+0] = pkd_data.val0;
          xref_d[sram_data_word_number*4+1] = pkd_data.val1;
          xref_d[sram_data_word_number*4+2] = pkd_data.val2;
          xref_d[sram_data_word_number*4+3] = pkd_data.val3;
        end
         // If end move to next state
        if(request_sram_done)
          rd_fsm_state_d = READ_MEM_FSM_STATE_5_VEC_XSTATE;
      end
      READ_MEM_FSM_STATE_5_VEC_XSTATE: begin
        // Request the read
        request_sram_read = 1'b1;
        sram_n_words      = X_VEC_DIM/4;
        sram_addr_word    = reg2hw.controller.X_IN_VEC.POINTER.value;
        // Once we get the input
        if(sram_rvalid_word) begin
          pkdw_fxp_s8_q4p4_t pkd_data;
          pkd_data = sram_rdata_word;
          xstate_d[sram_data_word_number*4+0] = pkd_data.val0;
          xstate_d[sram_data_word_number*4+1] = pkd_data.val1;
          xstate_d[sram_data_word_number*4+2] = pkd_data.val2;
          xstate_d[sram_data_word_number*4+3] = pkd_data.val3;
        end
         // If end move to next state
        if(request_sram_done)
          rd_fsm_state_d = READ_MEM_FSM_STATE_1_IDLE;
      end
    endcase

    // Drive FF input from combinational working wire
    rd_ptr_offset_d = rd_ptr_offset_c;

  end

  `FF(rd_fsm_state_q,  rd_fsm_state_d,  READ_MEM_FSM_STATE_0_RST, clk_i, rst_ni)
  `FF(rd_ptr_offset_q, rd_ptr_offset_d, '0,                       clk_i, rst_ni)

endmodule
