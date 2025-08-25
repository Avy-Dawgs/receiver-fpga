module tb_Log2(); 

  localparam CLK_PERIOD = 1;

  reg clk; 
  reg rst; 

  reg valid_i;
  reg [31:0] x; 

  wire [12:0] log2;
  wire valid_o;

  real log2_real;

  assign log2_real = real'(log2) / 2**8;

  initial begin 
    clk = 0; 
    forever #(0.5*CLK_PERIOD) begin  
      clk = ~clk;
    end
  end

  initial begin 
    rst = 1; 
    valid_i = 0;
    x = 0;
    #CLK_PERIOD; 
    rst = 0; 

    x = 0; 
    valid_i = 1;
    #CLK_PERIOD; 
    x = 1; 
    #CLK_PERIOD;
    x = 2; 
    #CLK_PERIOD;
    x = 3; 
    #CLK_PERIOD;
    x = 18;
    #CLK_PERIOD;
    x = 100;
    #CLK_PERIOD;
    x = 16_034_128;
    #CLK_PERIOD;
    valid_i = 0;
  end

  Log2 
  #(
    .DW(32), 
    .FRAC_BITS(8)
  )
  log2_mod 
  (
    .clk(clk), 
    .rst(rst), 
    .valid_i(valid_i),
    .x(x), 
    .log2(log2),
    .valid_o(valid_o)
  );

endmodule
