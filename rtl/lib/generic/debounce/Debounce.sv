/*
* Debounces.
*/
module Debounce #(
  STEADY_STATE_EN_COUNT
) (
  input clk, 
  input rst, 
  input en_i,
  input in,
  output reg out
);

  reg [$clog2(STEADY_STATE_EN_COUNT) - 1:0] steady_state_count;

  reg in0, in1, in2;

  // input register 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      in0 <= 1'h0;
      in1 <= 1'h0;
      in2 <= 1'h0;
    end
    else begin 
      in0 <= in; 
      in1 <= in0;
      in2 <= in1;
    end
  end

  // output register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      out <= 1'h0;
    end
    else if (steady_state_count == STEADY_STATE_EN_COUNT) begin 
      out <= in2;
    end
  end

  // count register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      steady_state_count <= 'h0;
    end 
    else begin 
      // reset count if no match
      if (in1 != in0) begin 
        steady_state_count <= 'h0;
      end
      else if (en_i && (steady_state_count != STEADY_STATE_EN_COUNT)) begin 
        steady_state_count <= steady_state_count + 1'h1;
      end
    end
  end

endmodule
