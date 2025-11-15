/*
* Convertes complex to magnitude squared.
*/
module Complex2Power #(
  DW, 
  QBITS
  ) (
  input clk, 
  input rst, 
  input signed [DW - 1:0] data_i_re,
  input signed [DW - 1:0] data_i_im,
  input valid_i,
  output reg [DW + 1 - 1:0] power_o,
  output reg valid_o
  ); 

  reg signed [DW - 1:0] im_reg, re_reg;
  reg valid_i_reg;

  // multiplier
  logic signed [2*DW - 1:0] sq; 

  function automatic [DW - 1:0] sq_fixed; 
    input signed [DW - 1:0] a; 
    logic [2*DW - 1:0] prod;
    begin 
      prod = a * a; 
      return prod >>> QBITS;
    end
  endfunction

  /******************** 
  * Sequential 
  * ******************/

  // input registers
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      re_reg <= 'h0;
      im_reg <= 'h0;
      valid_i_reg <= 1'h0;
    end
    else if (valid_i) begin 
      re_reg <= data_i_re;
      im_reg <= data_i_im;
      valid_i_reg <= 1'h1;
    end
  end

  // output registers 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      power_o <= 'h0; 
      valid_o <= 1'h0;
    end 
    else if (valid_i_reg) begin 
      power_o <= sq_fixed(.a(re_reg)) + sq_fixed(.a(im_reg));
      valid_o <= 1'h1;
    end
  end

endmodule
