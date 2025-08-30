/*
* Sine LUT based on a quarter sine wave LUT.
*/
module SineLut 
#(
  ADDR_BITS, 
  DW
)
(
  input clk, 
  input rst, 
  input [ADDR_BITS - 1:0] addr_i, 
  output logic signed [DW - 1:0] sample_o
); 

  localparam QLUT_ADDR_BITS = ADDR_BITS - 2;
  localparam QLUT_SIZE = 2**QLUT_ADDR_BITS;

  logic qlut_addr;
  wire qlut_sample;

  // second and fourth quadrants: go backwards
  assign qlut_addr = addr_i[ADDR_BITS - 2] ? (QLUT_SIZE - 1) - addr_i : addr_i;

  // third and fourth quadrants: invert sample
  assign sample_o = addr_i[ADDR_BITS - 1] ? -qlut_sample : qlut_sample;

  QuarterSineLut 
  #(
    .ADDR_BITS(QLUT_ADDR_BITS), 
    .DW(DW)
  )
  qlut 
  (
    .clk(clk), 
    .rst(rst), 
    .addr_i(qlut_addr), 
    .sample_o(qlut_sample)
  );

endmodule
