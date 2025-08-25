
`timescale 10ns/1ns

module tb_GoertzelPower(); 

  localparam FRAC_BITS = 4;

  localparam real PI = 3.141592653589763;

  localparam CLK_PERIOD = 2; 

  reg clk; 
  reg rst;
  reg start;
  reg signed [15:0] data; 
  reg valid_i; 
  wire done; 
  wire [31:0] power;

  real power_dB;
  real magnitude;

  assign power_dB = 10.0 * $log10(real'(power));
  assign magnitude = $sqrt(real'(power));

  initial begin 
    clk = 0; 
    forever #(CLK_PERIOD/2) begin 
      clk = ~clk;
    end
  end

  initial begin 
    rst = 1; 
    start = 0; 

    #CLK_PERIOD; 

    rst = 0;
    start = 1;
  end

  real t;

  initial begin 
    data = 0; 
    valid_i = 0;
    t = 0;

    #CLK_PERIOD;

    forever #9 begin 
      data = $rtoi(1000 * $cos(2 * PI * 457_000 * t)) << FRAC_BITS;
      valid_i = 1;
      #CLK_PERIOD; 
      valid_i = 0;

      t += 100e-9;
    end
  end

  GoertzelPower 
  #(
    .FREQ(457_000), 
    .SIZE(2**16),
    .SAMP_RATE(10_000_000), 
    .FRAC_BITS(FRAC_BITS)
  ) 
  goertzel 
  (
    .clk(clk), 
    .rst(rst), 
    .start_i(start), 
    .data_i(data), 
    .valid_i(valid_i),
    .done_o(done),
    .power_o(power)
  );

endmodule
