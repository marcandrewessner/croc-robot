
`include "common_cells/registers.svh"


/*
* Interface to read and write n amounts of words into memory
* memory must be sequential. And latency is one cycle
* 
* read mode:
* - provide the addr_word_i (starting address)
*   and number of words to be read
* - note the receiver needs to be able to take the data data_word_o
*   directly in, as soon as data_word_valid_o goes high
* - the last data_word_valid_o is marked with request_done_o at the same time
*
* write mode:
* - provide the addr_word_i (starting address)
*   and number of words to be written
* - note the transmitter needs to be able to provide the data_word_i
*   directly, as soon as data_word_request_o goes high
* - once the write is fully finished request_done_o is set to high
*
* note: 
* (1) write and reset request at the same time results in an error,
* (2) write and read are both latched and therefore cannot be aborted
*/

module controller_memory_interface #(
  /// OBI
  parameter type mgr_obi_req_t = logic,
  parameter type mgr_obi_rsp_t = logic
) (
  input logic clk_i,
  input logic rst_ni,
  /// OBI
  output mgr_obi_req_t mgr_obi_req_o,
  input  mgr_obi_rsp_t mgr_obi_rsp_i,
  // Read N words control
  input  logic request_read_i,
  output logic [31:0] data_word_o,
  output logic data_word_valid_o,
  // Write N word control
  input  logic request_write_i,
  input  logic [31:0] data_word_i,
  output logic data_word_request_o,
  // Shared RW control
  input  logic [31:0] addr_word_i,
  input  logic [31:0] n_words_i,
  output logic [31:0] data_word_number_o,
  output logic request_done_o,
  // Error
  output logic err_o
);

  // req_counter: advances on gnt (drives address), rsp_counter: advances on rvalid (drives done)
  logic [31:0] req_counter_d, req_counter_q;
  logic [31:0] word_counter_d, word_counter_q;
  logic [31:0] n_words_d, n_words_q;

  // Speak OBI to interact with memory
  logic req_read_d, req_read_q;
  logic req_write_d, req_write_q;
  logic [31:0] addr_word_d, addr_word_q;

  always_comb begin

    // Output defaults
    request_done_o     = 0;
    data_word_number_o = 0;
    data_word_valid_o  = 0;

    // Latch / Input the signals
    req_read_d  = req_read_q;
    req_write_d = req_write_q;
    addr_word_d = addr_word_q;
    n_words_d   = n_words_q;
    // Latch internal signals
    req_counter_d  = req_counter_q;
    word_counter_d = word_counter_q;

    // If we are not in request mode, pass throught the inputs
    if(!(req_read_q | req_write_q)) begin
      req_read_d  = request_read_i;
      req_write_d = request_write_i;
      addr_word_d = addr_word_i;
      n_words_d   = n_words_i;
      req_counter_d  = 0;
      word_counter_d = 0;
    end

    // Handle the requests
    if(req_read_q & req_write_q) begin
      err_o          = 1;
      data_word_o    = 'h0BADC0DE;
      request_done_o = 1;
      req_read_d     = 0;
      req_write_d    = 0;
    end else if(req_read_q) begin
      // req_counter advances on gnt (request accepted), word_counter on rvalid (response received)
      req_counter_d      = req_counter_q  + (mgr_obi_rsp_i.gnt    && (req_counter_q  < n_words_q) ? 'd1 : 'd0);
      word_counter_d     = word_counter_q + (mgr_obi_rsp_i.rvalid ? 'd1 : 'd0);
      data_word_valid_o  = mgr_obi_rsp_i.rvalid;
      data_word_o        = mgr_obi_rsp_i.r.rdata;
      data_word_number_o = word_counter_q;
      // When we have a vaild and end of word_counter, we are done
      if(word_counter_q >= (n_words_q-1) && mgr_obi_rsp_i.rvalid) begin
        request_done_o = 1;
        req_read_d     = 0;
      end
    end else if(req_write_q) begin
      // req_counter advances on gnt (request accepted), word_counter on rvalid (response received)
      req_counter_d       = req_counter_q  + (mgr_obi_rsp_i.gnt    && (req_counter_q  < n_words_q) ? 'd1 : 'd0);
      word_counter_d      = word_counter_q + (mgr_obi_rsp_i.rvalid ? 'd1 : 'd0);
      data_word_number_o  = word_counter_q;
      data_word_request_o = mgr_obi_rsp_i.gnt;
      // When we have a vaild and end of word_counter, we are done
      if(word_counter_q >= (n_words_q-1) && mgr_obi_rsp_i.rvalid) begin
        request_done_o = 1;
        req_write_d    = 0;
      end
    end

    // Drive the OBI bus — gate req once all n_words requests have been sent
    mgr_obi_req_o.req     = (req_read_q ^ req_write_q) && (req_counter_q < n_words_q);
    mgr_obi_req_o.a.addr  = addr_word_q + (req_counter_q*4);
    mgr_obi_req_o.a.we    = req_write_q;
    mgr_obi_req_o.a.wdata = data_word_i;
    mgr_obi_req_o.a.aid   = 0;

    // Publish Answer
    err_o = err_o | mgr_obi_rsp_i.r.err;

  end

  `FF(req_counter_q, req_counter_d, '0, clk_i, rst_ni)
  `FF(req_read_q, req_read_d, '0, clk_i, rst_ni)
  `FF(req_write_q, req_write_d, '0, clk_i, rst_ni)
  `FF(n_words_q, n_words_d, '0, clk_i, rst_ni)
  `FF(addr_word_q, addr_word_d, '0, clk_i, rst_ni)
  `FF(word_counter_q, word_counter_d, '0, clk_i, rst_ni)

endmodule