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
  output reg signed [FRAC_BITS:0] sample_o
); 

  localparam SIZE = 2**ADDR_BITS;     // full lut size
  localparam QLUT_ADDR_BITS = ADDR_BITS - 2; 
  localparam QLUT_SIZE = 2**QLUT_ADDR_BITS;   // quarter lut size

  localparam real PI = 3.1415926535;

  logic [QLUT_ADDR_BITS - 1:0] qlut_addr;
  logic [FRAC_BITS:0] qlut_sample;

  reg [FRAC_BITS:0] qlut [0:2**QLUT_ADDR_BITS - 1];

  initial begin 
    for (int i = 0; i < QLUT_SIZE; i++) begin 
      qlut[i] = $rtoi($sin(2 * PI * i / (4 * SIZE)) * 2**FRAC_BITS);
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      sample_o <= 'h0;
    end 
    else begin 
      // third and fourth quadrants: invert sample
      sample_o <= addr_i[ADDR_BITS - 1] ? -qlut_sample : qlut_sample;
    end
  end

  // second and fourth quadrants: go backwards
  assign qlut_addr = addr_i[ADDR_BITS - 2] ? 
    (QLUT_SIZE - 1) - addr_i[QLUT_ADDR_BITS - 1:0] : 
    addr_i[QLUT_ADDR_BITS - 1:0];

  assign qlut_sample = qlut[qlut_addr];

endmodule
