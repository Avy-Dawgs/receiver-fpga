/*
* Counts microseconds
*/
module Counter_us
#(
  CLK_FREQ, 
  MAX_COUNT
) 
(
  input clk, 
  input rst,
  input clr_i,
  output reg [$clog2(MAX_COUNT) - 1:0] count_o
); 

  wire us_en;

  logic en_gen_rst;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst || clr_i) begin 
      count_o <= 'd0;
    end
    else begin 
      if (us_en) begin 
        if (count_o == MAX_COUNT) begin 
          count_o <= 'h0;
        end
        else begin 
          count_o <= count_o + 1'd1;
        end
      end
    end
  end
  

  assign en_gen_rst = clr_i | rst;


  EnableGenerator 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(1_000_000)
  )
  us_en_gen
  (
    .clk(clk), 
    .rst(en_gen_rst), 
    .en_o(us_en)
  );

endmodule
