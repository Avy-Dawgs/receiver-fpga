/*
* Sine LUT based on a quarter sine wave LUT. 
* Latency is one clock cycle.
* 1.Q format
*/
module SineLut 
#(
  ABITS,  // address bits
  QBITS   // fractional bits
)
(
  input clk, 
  input rst, 
  input [ABITS - 1:0] addr_i, 
  output reg signed [QBITS:0] sample_o
); 

  // Logical description:
  //  1. Determine address for quarter LUT
  //    * Phase in first or third quadrant: address is as provided 
  //    * Phase in second or fourth quadrant: address is subtracted from max address
  //  2. Read sample from quarter LUT
  //  3. Adjust sample from quarter LUT sample
  //    * Phase in first or second quadrant: sample is as provided (positive)
  //    * Phase in third or fourth quadrant: sample is inverted (negative)

  localparam real PI = 3.1415926535;

  localparam SIZE = 2**ABITS;     // full LUT size
  localparam QLUT_ABITS = ABITS - 2; 
  localparam QLUT_SIZE = 2**QLUT_ABITS;   // quarter LUT size
  localparam QLUT_MADDR = QLUT_SIZE - 1;  // quarter LUT max address

  // quarter size LUT
  reg [QBITS:0] qlut [0:2**QLUT_ABITS - 1];

  // address for quarter LUT
  logic [QLUT_ABITS - 1:0] qlut_addr;     
  // sample from quarter LUT (note that sign bit is assumed here because it will always be positive)
  logic [QBITS - 1:0] qlut_sample;            
  // qlut sample but with positive sign applied
  logic signed [QBITS:0] qlut_sample_signed;  

  // define contents of LUT
  initial begin 
    for (int i = 0; i < QLUT_SIZE; i++) begin 
      qlut[i] = $rtoi($sin(2 * PI * i / (SIZE)) * 2**QBITS);
    end
  end

  // register output
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      sample_o <= 'h0;
    end 
    else begin 
      // third and fourth quadrants: invert sample
      sample_o <= addr_i[ABITS - 1] ? -qlut_sample_signed : qlut_sample_signed;
    end
  end

  // second and fourth quadrants: address is subtracted from max address
  assign qlut_addr = addr_i[ABITS - 2] ? 
    QLUT_MADDR - addr_i[QLUT_ABITS - 1:0] : 
    addr_i[QLUT_ABITS - 1:0];

  assign qlut_sample = qlut[qlut_addr];
  // add a sign bit (always positve because its directly from the LUT)
  assign qlut_sample_signed = $signed({1'h0, qlut_sample});

endmodule
