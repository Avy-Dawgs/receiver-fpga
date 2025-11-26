/*
* Interface for Adc. (LTC2315)
*/
module AdcInterface (
  input sck, 
  input rst,
  input miso,
  output reg cs_n,
  output reg [11:0] data_o, 
  output reg valid_o, 
  output reg error_o
); 

  reg [4:0] falling_edge_count;
  reg [11:0] shiftreg; 
  reg [1:0] sample_count;
  reg error;     // start bit error

  logic start_conv; 
  logic start_acq;

  // sample count
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      sample_count <= 'd0;
    end 
    else if (start_acq) begin 
      // saturate at 3
      if (sample_count < 'd3) begin 
        sample_count <= sample_count + 1'd1;
      end
    end
  end

  // shiftreg
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end 
    else begin 
      shiftreg <= {shiftreg[10:0], miso};
    end
  end

  // falling edge count
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      falling_edge_count <= 'd14;
    end
    else begin 
      if (start_conv) begin 
        falling_edge_count <= 'h0;
      end
      else begin 
        falling_edge_count <= falling_edge_count + 1'h1;
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

  // error
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      error <= 1'h0;
    end 
    else begin 
      if (falling_edge_count == 'h0) begin 
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
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      data_o <= 'h0;
    end
    else begin 
      if (falling_edge_count == 'd12) begin 
        data_o <= shiftreg;
      end
    end
  end

  always_ff @(posedge sck, posedge rst) begin 
    if (rst) begin 
      valid_o <= 1'h0;
      error_o <= 1'h0;
    end 
    else if (sample_count == 'd3) begin 
      if (falling_edge_count == 'd14) begin
        valid_o <= 1'h1; 
        error_o <= error;
      end
    end
  end

  assign start_conv = (falling_edge_count == 'd17);
  assign start_acq = (falling_edge_count == 'd13);

endmodule
