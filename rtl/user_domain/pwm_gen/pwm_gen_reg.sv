
`include "common_cells/registers.svh"

module pwm_gen_reg import pwm_gen_pkg::*; #(
  /// The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request type
    parameter type obi_req_t = logic,
    /// OBI response type
    parameter type obi_rsp_t = logic
) (
  input logic clk_i,
  input logic rst_ni,

  // OBI connect
  input obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  // Output the register
  output pwm_reg_field_t pwm_reg_o
);


  //////////////////////////////////////////////////
  // OBI Interface Preparations //
  //////////////////////////////////////////////////

  // Signals for OBI
  logic                             obi_a_req_in_d, obi_a_req_in_q; // delayed for response
  logic [ObiCfg.AddrWidth-1:0]      obi_a_addr_in_d, obi_a_addr_in_q;
  logic [ObiCfg.DataWidth-1:0]      obi_a_wdata_in_d, obi_a_wdata_in_q;
  logic [ObiCfg.IdWidth-1:0]        obi_a_id_in_d, obi_a_id_in_q;       // delayed for response
  logic                             obi_a_we_in_d, obi_a_we_in_q;       // delayed for response

  logic [ObiCfg.DataWidth-1:0]      obi_r_rspdata_out;
  logic                             obi_r_err_out;

  // OBI assignment
  always_comb begin
    // obi_req_i
    obi_a_req_in_d   = obi_req_i.req;
    obi_a_addr_in_d  = obi_req_i.a.addr;
    obi_a_wdata_in_d = obi_req_i.a.wdata;
    obi_a_id_in_d    = obi_req_i.a.aid;
    obi_a_we_in_d    = obi_req_i.a.we;
    // obi_rsp_o
    obi_rsp_o = '0;
    obi_rsp_o.gnt    = obi_a_req_in_d;
    obi_rsp_o.rvalid = obi_a_req_in_q;
    obi_rsp_o.r.rdata = obi_r_rspdata_out;
    obi_rsp_o.r.rid  = obi_a_id_in_q;
    obi_rsp_o.r.err  = obi_r_err_out;
  end

  `FF(obi_a_req_in_q, obi_a_req_in_d, '0, clk_i, rst_ni)
  `FF(obi_a_addr_in_q, obi_a_addr_in_d, '0, clk_i, rst_ni)
  `FF(obi_a_wdata_in_q, obi_a_wdata_in_d, '0, clk_i, rst_ni)
  `FF(obi_a_id_in_q, obi_a_id_in_d, '0, clk_i, rst_ni)
  `FF(obi_a_we_in_q, obi_a_we_in_d, '0, clk_i, rst_ni)

  //////////////////////////////////////////////////
  // Initialize the registers //
  //////////////////////////////////////////////////
  pwm_reg_field_t reg_d, reg_q;
  assign pwm_reg_o = reg_q;

  `FF(reg_q, reg_d, PWMRegResetVal, clk_i, rst_ni)


  //////////////////////////////////////////////////
  // OBI Interface //
  //////////////////////////////////////////////////
  /*
  *   The interface ignores the byte enable (whole registers are written)
  *   Single Cycle with req and gnt being coupled
  */
  
  logic [AddressBits-1:0] addr_offset;
  assign addr_offset = obi_a_addr_in_d[AddressBits-1:0];

  always_comb begin : pwm_obi_write
    reg_d = reg_q; 
    obi_r_rspdata_out = '0;
    obi_r_err_out     = '0;
    if(obi_a_req_in_d && obi_a_we_in_d) begin
      case (addr_offset)
        RegAddrControl: reg_d.pwm_ctrl        = 8'(obi_a_wdata_in_d);
        RegAddrTop:     reg_d.counter_top     = obi_a_wdata_in_d;
        RegAddrCompare: reg_d.counter_compare = obi_a_wdata_in_d;
        default: obi_r_err_out = 1;
      endcase
    end
    else if(obi_a_req_in_d && !obi_a_we_in_d) begin
      case (addr_offset)
        RegAddrControl: reg_d.pwm_ctrl        = ObiCfg.DataWidth'(obi_a_wdata_in_d);
        RegAddrTop:     reg_d.counter_top     = obi_a_wdata_in_d;
        RegAddrCompare: reg_d.counter_compare = obi_a_wdata_in_d;
        default: obi_r_err_out = 1;
      endcase
    end
  end


endmodule