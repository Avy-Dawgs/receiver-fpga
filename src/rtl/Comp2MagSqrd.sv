/*
* Convertes complex to magnitude squared.
*/
module Comp2MagSqrd #(
  DW
  ) (
  input clk, 
  input rst, 
  input [DW - 1:0] data_i,  // interleaved real, imag
  input valid_i,
  input last_i,
  output reg [2*DW - 1:0] mag_sqrd_o,
  output valid_o
  ); 

  reg [DW - 1:0] data_reg;
  reg valid_reg;
  reg last_reg;

  // multiplier
  logic [2*DW - 1:0] sq; 

  /******************** 
  * Sequential 
  * ******************/

  // input registers
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      data_reg <= 'h0;
      valid_reg <= 1'h0; 
      last_reg <= 1'h0;
    end
    else begin 
      data_reg <= data_i;
      valid_reg <= valid_i; 
      last_reg <= last_i;
    end
  end

  // output registers 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      mag_sqrd_o <= 'h0; 
      valid_o <= 1'h0;
    end 
    else begin 
      if (valid_reg) begin 
        // real (first channel)
        if (!last_reg) begin 
          mag_sqrd_o <= sq;
          valid_o <= 1'h0;
        end
        // imag (second channel)
        else begin 
          mag_sqrd_o <= mag_sqrd_o + sq;
          valid_o <= 1'h1;
        end
      end
      else begin 
        valid_o <= 1'h0;
      end
    end
  end

  assign sq = data_reg * data_reg;

endmodule
