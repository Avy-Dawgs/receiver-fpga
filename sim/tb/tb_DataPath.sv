module tb_DataPath(); 

  reg clk; 
  reg rst;
  logic en_i; 

  reg signed [11:0] sample; 
  reg sample_valid;

  wire [15:0] dB;
  wire dB_valid;

  localparam T = 2;
  localparam PI = 3.1415926535;

  // clock 
  initial begin 
    clk = 0; 
    forever #1 begin 
      clk = ~clk; 
    end
  end

  real t; 

  initial begin 
    sample = 'h0;
    sample_valid = 1'h0;
    rst = 1; 
    #T; 
    rst = 0;

    t = 0;
    for(int i = 0; i < 10_000_000; i++) begin 
      #(9*T);
      sample = (2**11) + 1000 * $sin(2*PI*45.7e3*t);
      sample_valid = 1'h1;
      #T;
      t += 1.0/(1e6);
    end
  end

  assign en_i = 1'h1;

  DataPath #(
    .SAMP_RATE(1_000_000), 
    .MIXER_FREQ(45_700)
  ) dut (
    .clk(clk), 
    .rst(rst), 
    .en_i(en_i), 
    .adc_sample_i(sample), 
    .adc_sample_valid_i(sample_valid), 
    .dB_o(dB), 
    .valid_o(dB_valid)
  ); 

endmodule
