module EdgeDetector_asynchronous (
  input clk, 
  input rst, 
  input test_clk, 
  output rising_edge, 
  output falling_edge
); 

  reg q1, q2, q3;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      q1 <= 1'h0; 
      q2 <= 1'h0;
      q3 <= 1'h0;
    end
    else begin 
      q1 <= test_clk; 
      q2 <= q1;
      q3 <= q2;
    end
  end

  assign rising_edge = (~q3) & q2;
  assign falling_edge = q3 & (~q2);

endmodule
