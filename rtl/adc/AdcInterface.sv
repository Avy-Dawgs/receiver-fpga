/*
* Interface for Adc. (LTC2315)
*/
module AdcInterface (
  input sck, 
  input rst,
  input mosi,
  output reg cs_n,
  output [11:0] data_o, 
  output valid_o
); 

  reg [4:0] rising_edge_count;
  reg [11:0] shiftreg; 

  logic start_conv; 
  logic start_acq;

  // shiftreg
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end 
    else begin 
      shiftreg <= {shiftreg[10:0], mosi};
    end
  end

  // rising edge count
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      rising_edge_count <= 'd14;
    end
    else begin 
      if (start_conv) begin 
        rising_edge_count <= 'h0;
      end
      else begin 
        rising_edge_count <= rising_edge_count + 1'h1;
      end
    end
  end

  // cs_n
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      cs_n <= 1'h1;
    end 
    else begin 
      if (start_conv) begin 
        cs_n <= 1'h0;
      end
      else if (start_acq) begin 
        cs_n <= 1'h1;
      end
    end
  end

  assign start_conv = (rising_edge_count == 'd17);
  assign start_acq = (rising_edge_count == 'd13);

  assign valid_o = start_acq;
  assign data_o = shiftreg;

endmodule
