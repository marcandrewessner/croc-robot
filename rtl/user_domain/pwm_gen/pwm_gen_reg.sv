
`include "common_cells/registers.svh"

module pwm_gen_reg import pwm_gen_pkg::*; #(
  /// The OBI configuration for all ports.
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request type
    parameter type obi_req_t = logic,
    /// OBI response type
    parameter type obi_rsp_t = logic,
    // Number of registers for pwm signals used
    parameter int unsigned NrPWMRegs = 1
) (
  input logic clk_i,
  input logic rst_ni,

  // OBI connect
  input obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  // Output the register
  output pwm_reg_field_t pwm_reg_bank_o [NrPWMRegs]
);


  //////////////////////////////////////////////////
  // OBI Interface Preparations //
  //////////////////////////////////////////////////

  // Signals for OBI
  logic                             obi_a_req_in_d, obi_a_req_in_q;     // delayed for response
  logic [ObiCfg.AddrWidth-1:0]      obi_a_addr_in;
  logic [ObiCfg.DataWidth-1:0]      obi_a_wdata_in;
  logic [ObiCfg.IdWidth-1:0]        obi_a_id_in_d, obi_a_id_in_q;       // delayed for response
  logic                             obi_a_we_in_d, obi_a_we_in_q;       // delayed for response

  logic [ObiCfg.DataWidth-1:0]      obi_r_rspdata_out;
  logic                             obi_r_err_out;

  // OBI assignment
  always_comb begin
    // obi_req_i
    obi_a_req_in_d   = obi_req_i.req;
    obi_a_addr_in  = obi_req_i.a.addr;
    obi_a_wdata_in = obi_req_i.a.wdata;
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
  `FF(obi_a_id_in_q, obi_a_id_in_d, '0, clk_i, rst_ni)
  `FF(obi_a_we_in_q, obi_a_we_in_d, '0, clk_i, rst_ni)

  //////////////////////////////////////////////////
  // Initialize the registers //
  //////////////////////////////////////////////////
  pwm_reg_field_t reg_bank_d[NrPWMRegs];
  pwm_reg_field_t reg_bank_q[NrPWMRegs];
  assign pwm_reg_bank_o = reg_bank_q;
  `FF(reg_bank_q, reg_bank_d, '{default:PWMRegResetVal}, clk_i, rst_ni)

  //////////////////////////////////////////////////
  // OBI Interface //
  //////////////////////////////////////////////////
  /*
  *   The interface ignores the byte enable (whole registers are written)
  *   Single Cycle with req and gnt being coupled
  */
  always_comb begin : pwm_obi
    logic [AddressRegisterOffsetBits-1:0]  addr_offset_reg;
    logic [AddressInstanceBits-1:0]        addr_offset_instance;
    pwm_reg_field_t reg_d_selected;

    reg_d_selected       = 'x; // explicitly set to undefined
    reg_bank_d           = reg_bank_q;
    obi_r_rspdata_out    = '0;
    obi_r_err_out        = '0;
    addr_offset_reg      = obi_a_addr_in[2 +: AddressRegisterOffsetBits];
    addr_offset_instance = obi_a_addr_in[2+AddressRegisterOffsetBits +: AddressInstanceBits];

    // Load the register q into selected
    // and raise err for non existing instance
    if(obi_a_req_in_d) begin
      obi_r_err_out = 'b1;
      for(int i=0; i<NrPWMRegs; i++) begin
        if(addr_offset_instance==i) begin
          reg_d_selected = reg_bank_q[i];
          obi_r_err_out = '0;
        end
      end
    end

    // Write Request
    if(obi_a_req_in_d && obi_a_we_in_d) begin
      case (addr_offset_reg)
        RegAddrControlWordOffset: reg_d_selected.pwm_ctrl        = 8'(obi_a_wdata_in);
        RegAddrTopWordOffset:     reg_d_selected.counter_top     = obi_a_wdata_in;
        RegAddrCompareWordOffset: reg_d_selected.counter_compare = obi_a_wdata_in;
        default: obi_r_err_out = 1;
      endcase
      
      // Now load the selected register data into d
      // should be the already overwritten data
      for(int i=0; i<NrPWMRegs; i++) begin
        if(addr_offset_instance==i) begin
          reg_bank_d[i] = reg_d_selected;
        end
      end
    end
    
    // Read Request
    else if(obi_a_req_in_d && !obi_a_we_in_d) begin
      case (addr_offset_reg)
        RegAddrControlWordOffset: obi_r_rspdata_out = reg_d_selected.pwm_ctrl;
        RegAddrTopWordOffset:     obi_r_rspdata_out = reg_d_selected.counter_top;
        RegAddrCompareWordOffset: obi_r_rspdata_out = reg_d_selected.counter_compare;
        default: obi_r_err_out = 'b1;
      endcase
    end

  end


endmodule