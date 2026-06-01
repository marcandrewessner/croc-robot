
///////////////////////
// Vec A·B (dot)     //
// scalar output     //
///////////////////////

module vec_dot_signed_sat #(
  parameter int VEC_W,     // Number of elements in each vector
  parameter int NUM_W = 8, // Width of each data element
  // Intermediate widths: sized to hold any possible result without intermediate saturation
  localparam int MUL_W = 2 * NUM_W,             // exact product width for NUM_W × NUM_W
  localparam int ACC_W = MUL_W + $clog2(VEC_W), // enough to sum VEC_W full products losslessly
  localparam type elem_t = logic signed [NUM_W-1:0],
  localparam type vec_t  = elem_t [VEC_W-1:0]
) (
  input  vec_t                    A_i,
  input  vec_t                    B_i,
  output logic signed [NUM_W-1:0] X_o
);

  always_comb begin : dot_product_signed_with_saturation

    logic signed [MUL_W-1:0] prod [VEC_W];
    logic signed [ACC_W-1:0] acc;

    // Full-precision multiply per lane — no saturation, no rounding
    for (int i = 0; i < VEC_W; i++) begin
      prod[i] = MUL_W'(signed'(A_i[i])) * MUL_W'(signed'(B_i[i]));
    end

    // Lossless accumulate: ACC_W is wide enough that this never overflows
    acc = '0;
    for (int i = 0; i < VEC_W; i++) begin
      acc += ACC_W'(signed'(prod[i]));
    end

    // Saturate to NUM_W only at the output
    // Result fits iff the upper (ACC_W-NUM_W+1) bits are all equal (valid sign extension)
    if (&acc[ACC_W-1:NUM_W-1] || ~|acc[ACC_W-1:NUM_W-1]) begin
      X_o = acc[NUM_W-1:0];
    end else if (acc[ACC_W-1]) begin
      X_o = NUM_W'(-(2**(NUM_W-1)));  // neg overflow → MIN_INT
    end else begin
      X_o = NUM_W'(2**(NUM_W-1)-1);  // pos overflow → MAX_INT
    end

  end

endmodule
