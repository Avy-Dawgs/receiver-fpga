/*
* General purpose SPI deserializer that relies on external timing. 
* This is just a shiftreg, user must determin when to sample the data.
*/
module SpiDeserializer #(
  DW
) (
  input clk, 
  input rst, 
  input sck_sample_edge, // edge of sck to sample on 
  input mosi,     // serial input 
  input cs_n_falling_edge,
  output [DW - 1:0] data_o
  ); 

  reg [DW - 1:0] shiftreg;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end
    else begin 
      // clear the shiftreg on the falling edge of cs_n
      if (cs_n_falling_edge) begin 
        shiftreg <= 'h0;
      end
      // use the sample edge to shift in the data
      else if (sck_sample_edge) begin 
        shiftreg <= {shiftreg[DW - 1:1], mosi};
      end
    end
  end

  assign date_o = shiftreg;

endmodule
