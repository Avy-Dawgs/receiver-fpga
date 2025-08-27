/*
* Counts milliseconds
*/
module Counter_ms
#(
  CLK_FREQ, 
  MAX_COUNT
) 
(
  input clk, 
  input rst,
  output reg [$clog2(MAX_COUNT) - 1:0] count_o
); 

  wire ms_en;


  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count_o <= 'd0;
    end
    else begin 
      if (ms_en) begin 
        if (count_o == MAX_COUNT) begin 
          count_o <= 'h0;
        end
        else begin 
          count_o <= count_o + 1'd1;
        end
      end
    end
  end
  

  EnableGenerator 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(1_000)
  )
  ms_en_gen
  (
    .clk(clk), 
    .rst(rst), 
    .en_o(ms_en)
  );

endmodule
