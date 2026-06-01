
//////////////////////
// Vec A-B  //
// unpacked //
//////////////////////

module vec_sub_signed_sat #(
  parameter int VEC_W,     // Define how many items the vector (unpacked list)
  parameter int NUM_W = 8, // Define the width of the data items
  // Types used in module
  localparam int NUM_EXT_W = NUM_W+1,
  localparam type elem_t = logic signed [NUM_W-1:0],
  localparam type vec_t  = elem_t [VEC_W-1:0]
) (
  input  vec_t A_i, 
  input  vec_t B_i,
  output vec_t X_o
);

  always_comb begin : addition_signed_with_saturation
    
    // For signed addition extend each number
    for(int i=0; i<VEC_W; i++) begin
      
      logic signed [NUM_EXT_W-1:0] a_ext, b_ext, x_ext, x_res;
      
      // Extend the data for overflow detection
      a_ext = {A_i[i][NUM_W-1], A_i[i]};
      b_ext = {B_i[i][NUM_W-1], B_i[i]};
      x_ext = a_ext - b_ext;
      
      // Overflow detected when top 2 bits differ: 10 = neg overflow, 01 = pos overflow
      unique case (x_ext[NUM_EXT_W-1 -: 2])
        2'b10:   x_res = NUM_W'(-(2**(NUM_W-1)));  // neg overflow → MIN_INT
        2'b01:   x_res = NUM_W'(2**(NUM_W-1)-1);   // pos overflow → MAX_INT
        default: x_res = x_ext[NUM_W-1:0];         // no overflow
      endcase
      
      // Now propagate to output
      X_o[i] = x_res;
    end

  end



endmodule