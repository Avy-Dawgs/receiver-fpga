/*
* Multiplexor modules.
*/


module Mux2 #(
  DW
) 
(
  input [DW - 1:0] a, 
  input [DW - 1:0] b, 
  input sel,
  output [DW - 1:0] out
);

  assign out = sel ? b : a;

endmodule

module Mux4 #(
  DW
)
(
  input [DW - 1:0] a, 
  input [DW - 1:0] b, 
  input [DW - 1:0] c, 
  input [DW - 1:0] d,
  input [1:0] sel,
  output logic [DW - 1:0] out
  ); 

  always_comb begin 
    case (sel)
      2'b00: begin 
        out = a;
      end
      2'b01: begin 
        out = b;
      end
      2'b10: begin 
        out = c;
      end
      2'b11: begin 
        out = d;
      end
    endcase
  end

endmodule
