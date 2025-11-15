/*
* Generates human used time units.
*/
module TimeUnitGenerator#(
  CLK_FREQ
  ) (
  input clk, 
  input rst, 
  output reg us_en,
  output reg ms_en
); 

localparam COUNTER_DW = 10; 
localparam US_EN_FREQ = 1e-6;

reg [COUNTER_DW - 1:0] us_count;

logic max_us_count_reached;

// counter
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    us_count <= 'h0;   
  end
  else begin 
    if (us_en_internal) begin 
      // override and set back to zero 
      if (max_us_count_reached) begin 
        us_count <= 'h0;
      end
      // increment
      else begin 
        us_count <= us_count + 1'h1;
      end
    end
  end
end

// us enable
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    us_en <= 1'h0; 
  end
  else begin 
    us_en <= us_en_internal;
  end
end

// ms enable
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    ms_en <= 1'h0;
  end 
  else begin 
    if (us_en_internal && max_us_count_reached) begin 
      ms_en <= 1'h1;
    end
    else begin 
      ms_en <= 1'h0;
    end
  end
end

assign max_us_count_reached = (us_count == 'h999);

EnableGenerator #(
  .CLK_FREQ(CLK_FREQ), 
  .EN_FREQ(US_EN_FREQ)
  ) en_gen 
  (
    .clk(clk), 
    .rst(clk), 
    .en_o(us_en_internal)
  );

endmodule
