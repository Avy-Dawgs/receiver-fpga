/*
* Interface for Adc. (LTC2315)
*/
module AdcInterface (
  input sck, 
  input rst,
  input miso,
  output reg cs_n,
  output reg [11:0] data_o, 
  output valid_o, 
  output error_o
); 

  reg [4:0] rising_edge_count;
  reg [11:0] shiftreg; 

  reg error;     // start bit error

  logic start_conv; 
  logic start_acq;

  reg [1:0] sample_count;

  // sample count
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      sample_count <= 'd0;
    end 
    else if (start_acq) begin 
      if (sample_count < 'd3) begin 
        sample_count <= sample_count + 1'd1;
      end
    end
  end

  // shiftreg
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end 
    else begin 
      shiftreg <= {shiftreg[10:0], miso};
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

  // start bit error
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      error <= 1'h0;
    end 
    else begin 
      if (rising_edge_count == 'h0) begin 
        error <= (miso != 1'h0);
      end
      else if (start_acq) begin 
        if (!error) begin 
          error <= (miso != 1'h0);
        end
      end
    end
  end

  // output data reg
  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      data_o <= 'h0;
    end
    else begin 
      if (start_acq) begin 
        data_o <= shiftreg;
      end
    end
  end

  assign start_conv = (rising_edge_count == 'd17);
  assign start_acq = (rising_edge_count == 'd13);

  assign valid_o = (sample_count == 'd3) && (rising_edge_count == 'd15);
  assign error_o = valid_o && error;

endmodule
