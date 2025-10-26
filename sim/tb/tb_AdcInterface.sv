module tb_AdcInterface(); 

  reg sck; 
  reg rst; 
  reg mosi; 

  wire cs_n; 
  wire [11:0] data_o; 
  wire valid_o;

  reg [11:0] data_i;

  localparam T = 2;

  initial begin 
    sck = 0; 
    forever #1 begin 
      sck = ~sck; 
    end
  end

  initial begin 
    rst = 1; 
    mosi = 1;
    data_i = 11'h48F;
    #T;
    rst = 0;

    wait(cs_n == 0);

    for (int i = -1; i < 13; i++) begin 
      wait(sck == 1) wait(sck == 0);
      if (i >= 0 && i < 12) 
        mosi = data_i[11 - i];
    end

    #(50*T);
    $finish;
  end

  AdcInterface dut (
    .sck(sck), 
    .rst(rst), 
    .mosi(mosi), 
    .cs_n(cs_n), 
    .data_o(data_o), 
    .valid_o(valid_o)
  );

endmodule
