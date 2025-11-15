/*
* Simple counter that rolls over if not cleared.
*/
module Counter_wrap
#(
  DW
) 
(
  input clk, 
  input rst, 
  input clr_i, 
  input en_i,   // enable signal defining when to increment
  output reg [DW-1:0] count_o
); 

always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    count_o <= 'h0;
  end
  else if (en_i) begin 
    if (clr_i) begin 
      count_o <= 'h0;
    end
    else begin
      count_o <= count_o + 1'h1;
    end
  end
end

endmodule

