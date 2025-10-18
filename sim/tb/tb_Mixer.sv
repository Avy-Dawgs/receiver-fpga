module tb_Mixer(); 

localparam real PI = 3.141592653589763;

localparam DW = 12; 
localparam SAMP_RATE = 5_000_000; 
localparam FREQ = 457_000; 
localparam LUT_ABITS = 10;


localparam CLK_PERIOD = 2;

reg clk; 
reg rst; 
reg [DW - 1:0] data_i; 
reg valid_i; 
wire [DW - 1:0] data_o; 
wire valid_o;

reg [DW - 1:0] re; 
reg [DW - 1:0] im; 

logic [2*DW - 1:0] mag_sqrd;
real mag;

assign mag_sqrd = re*re + im*im;
assign mag = $sqrt(mag_sqrd);

reg valid_o_last;

// clock
initial begin 
  clk = 0; 
  forever #(CLK_PERIOD/2) begin 
    clk = ~clk;
  end
end

// reset
initial begin 
  rst = 1; 

  #CLK_PERIOD; 

  rst = 0;
end

real t;

// input signal
initial begin 
  data_i = 0; 
  valid_i = 0;
  t = 0;

  #CLK_PERIOD;

  forever #9 begin 
    data_i = $rtoi(1000 * $cos(2 * PI * FREQ * t));
    valid_i = 1;
    #CLK_PERIOD; 
    valid_i = 0;

    t += 1.0/real'(SAMP_RATE);
  end
end

always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    valid_o_last <= 1'h0; 
    re <= 'h0;
    im <= 'h0;
  end 
  else begin 
    valid_o_last <= valid_o; 

    if (!valid_o_last && valid_o) begin 
      re <= data_o;
    end
    if (valid_o_last && valid_o) begin 
      im <= data_o;
    end
  end
end


Mixer #(
  .DW(DW), 
  .SAMP_RATE(SAMP_RATE), 
  .FREQ(FREQ), 
  .LUT_ABITS(LUT_ABITS)
  ) dut (
    .clk(clk), 
    .rst(rst), 
    .data_i(data_i), 
    .valid_i(valid_i), 
    .data_o(data_o), 
    .valid_o(valid_o)
  );
endmodule
