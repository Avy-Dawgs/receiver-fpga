
`timescale 10ns/1ns

module tb_DcBlocker(); 

  localparam INPUT_DW = 12; 
  localparam INTERNAL_FRAC_BITS = 8; 
  localparam OUTPUT_FRAC_BITS = 4;

  localparam real PI = 3.141592653589763;

  localparam CLK_PERIOD = 2; 

  reg clk; 
  reg rst; 
  reg [INPUT_DW - 1:0] data_i; 
  reg en_i; 
  reg valid_i; 

  wire valid_o; 
  wire signed [16:0] data_o;

  initial begin 
    clk = 0; 
    forever #(CLK_PERIOD/2) begin 
      clk = ~clk;
    end
  end

  real t;
  initial begin 
    data_i = 0; 
    valid_i = 0;
    t = 0;

    #CLK_PERIOD;

    forever #9 begin 
      data_i = $rtoi(1000 * $cos(2 * PI * 457_000 * t)) + 2**(INPUT_DW - 1);
      valid_i = 1;
      #CLK_PERIOD; 
      valid_i = 0;

      t += 100e-9;
    end
  end

  initial begin 
    rst = 1; 
    en_i = 1;
    #CLK_PERIOD; 
    rst = 0;
  end

  DcBlocker #(
    .INPUT_DW(INPUT_DW), 
    .INTERNAL_FRAC_BITS(INTERNAL_FRAC_BITS), 
    .OUTPUT_FRAC_BITS(OUTPUT_FRAC_BITS)
  ) 
  blocker (
    .clk(clk), 
    .rst(rst), 
    .data_i(data_i), 
    .en_i(en_i), 
    .valid_i(valid_i), 
    .valid_o(valid_o),
    .data_o(data_o)
  );

endmodule
