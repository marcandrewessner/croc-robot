
//////////////////////
// Vec A+B  //
// unpacked //
//////////////////////

module vec_add_signed_sat #(
  parameter int VEC_W,     // Define how many items the vector (unpacked list)
  parameter int NUM_W = 8, // Define the width of the data items
  // Types used in module
  localparam int NUM_EXT_W = NUM_W+1
  localparam type elem_t = logic signed [NUM_W-1:0],
  localparam type vec_t  = elem_t [VEC_W],
) (
  input  vec_t A_i, 
  input  vec_t B_i,
  output vec_t X_o,
);

  always_comb begin : addition_signed_with_saturation
    
    // For signed addition extend each number
    for(int i=0; i<VEC_W; i++) begin
      
      logic signed [NUM_EXT_W-1:0] a_ext, b_ext, x_ext, x_res;
      
      // Extend the data for overflow detection
      a_ext = {a[i][NUM_W-1], a[i]};
      b_ext = {b[i][NUM_W-1], b[i]};
      x_ext = a_ext + b_ext;
      
      // Now check for saturation
      if(x_ext[i][NUM_EXT_W-1]==1'b1 && x_ext[i][NUM_EXT_W-2]==1'b0)       // neg w overflow
        x_res = NUM_W'(2**(NUM_W-1));
      else if(x_ext[i][NUM_EXT_W-1]==1'b1 && x_ext[i][NUM_EXT_W-2]==1'b0)  // pos overflow
        x_res = NUM_W'(2**(NUM_W-1));
      else
        x_res = {x_ext[NUM_EXT_W-1], x_ext[NUM_W-1:0]};
      
      // Now propagate to output
      x_out[i] = x_res;
    end

  end



endmodule