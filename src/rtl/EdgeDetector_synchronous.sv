/*
* Detect edges on a signal that is synchronous to the clock.
*/
module EdgeDetector_synchronous
(
  input clk, 
  input rst,
  input test_clk, 
  output rising_edge, 
  output falling_edge
); 

  reg prev_test_clk;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      prev_test_clk <= 1'h0;
    end
    else begin 
      prev_test_clk <= test_clk; 
    end
  end

  assign rising_edge = (~prev_test_clk) & test_clk; 
  assign falling_edge = prev_test_clk & (~test_clk);

endmodule
