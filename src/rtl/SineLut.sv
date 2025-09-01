/*
* Sine LUT based on a quarter sine wave LUT.
*/
module SineLut 
#(
  ADDR_BITS, 
  FRAC_BITS
)
(
  input clk, 
  input rst, 
  input [ADDR_BITS - 1:0] addr_i, 
  output logic signed [FRAC_BITS:0] sample_o
); 

  localparam QLUT_ADDR_BITS = ADDR_BITS - 2;
  localparam QLUT_SIZE = 2**QLUT_ADDR_BITS;

  logic qlut_addr;
  wire qlut_sample;

  // second and fourth quadrants: go backwards
  assign qlut_addr = addr_i[ADDR_BITS - 2] ? 
    (QLUT_SIZE - 1) - addr_i[QLUT_ADDR_BITS - 1:0] : 
    addr_i[QLUT_ADDR_BITS - 1:0];

  // third and fourth quadrants: invert sample
  assign sample_o = addr_i[ADDR_BITS - 1] ? -qlut_sample : qlut_sample;

  QuarterSineLut 
  #(
    .ADDR_BITS(QLUT_ADDR_BITS), 
    .FRAC_BITS(FRAC_BITS)
  )
  qlut 
  (
    .clk(clk), 
    .rst(rst), 
    .addr_i(qlut_addr), 
    .sample_o(qlut_sample)
  );

endmodule
