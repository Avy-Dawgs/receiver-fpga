/*
* One debouncer per input bit.
*/
module Debounce_wide #(
  DW, 
  STEADY_STATE_EN_COUNT
) (
  input clk, 
  input rst, 
  input en_i,
  input [DW - 1:0] in, 
  output [DW - 1:0] out
); 

generate 
  for (genvar i = 0; i < DW; i++) begin : gen_debounce
    Debounce #(
      .STEADY_STATE_EN_COUNT(STEADY_STATE_EN_COUNT)
    ) debounce (
      .clk(clk), 
      .rst(rst), 
      .en_i(en_i), 
      .in(in[i]), 
      .out(out[i])
    );
  end
endgenerate

endmodule
