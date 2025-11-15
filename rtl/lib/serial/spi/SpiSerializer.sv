/*
* General purpose SPI serializer, which is effectively just a shiftreg.
* cs_n_falling_edge determines when data is registerd into shiftreg.
* User nust override miso signal to desired value when not transmitting.
*/
module SpiSerializer #(
  DW
) (
  input clk, 
  input rst, 
  input [DW - 1:0] data_i,   // data to be transfered
  input sck_shift_edge,          // sck shift indicator
  input cs_n_falling_edge, 
  output miso        // serial output
); 

  reg [DW - 1:0] shiftreg;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end
    else begin 
      // register data on falling edge of cs_n
      if (cs_n_falling_edge) begin 
        shiftreg <= data_i;
      end
      // shift data out on shift edge
      else if (sck_shift_edge) begin 
        shiftreg <= shiftreg << 1'h1;
      end
    end
  end

  assign miso = shiftreg[DW-1];

endmodule
