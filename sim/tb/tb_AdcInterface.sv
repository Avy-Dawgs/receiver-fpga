module tb_AdcInterface(); 

  reg sck; 
  reg rst; 
  reg miso; 

  wire cs_n; 
  wire [11:0] data_o; 
  wire valid_o;
  wire error_o;

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
    miso = 1;
    data_i = 11'h48F;
    #T;
    rst = 0;

    @(negedge cs_n);

    for (int i = -1; i < 13; i++) begin 
      @(negedge sck);
      if (i >= 0 && i < 12) begin
        miso = data_i[11 - i];
      end
    end

    #(50*T);
    $finish;
  end

  AdcInterface dut (
    .sck(sck), 
    .rst(rst), 
    .miso(miso), 
    .cs_n(cs_n), 
    .data_o(data_o), 
    .valid_o(valid_o), 
    .error_o(error_o)
  );

endmodule
