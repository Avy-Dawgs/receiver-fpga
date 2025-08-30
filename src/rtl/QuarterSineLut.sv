/*
* LUT for a quarer sine wave.
*/
module QuarterSineLut 
#(
  ADDR_BITS, 
  DW
)
(
  input clk, 
  input rst, 
  input [ADDR_BITS - 1:0] addr_i, 
  output reg [DW - 1:0] sample_o
); 

  localparam real PI = 3.1415926535;

  reg [DW - 1:0] lut [0:2**ADDR_BITS - 1];

  initial begin 
    for (int i = 0; i < SIZE; i++) begin 
      lut[i] = $rtoi($sin(2 * PI * i / (4 * SIZE)) * 2**(DW - 1));
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      sample_o <= 'h0;
    end 
    else begin 
      sample_o <= lut[addr_i];
    end
  end

endmodule
