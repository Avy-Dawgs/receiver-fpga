module tb_PgaInterface(); 

  localparam CLK_FREQ = 50_000;
  localparam SCK_FREQ = 25_000;

  reg sck;
  reg rst; 
  reg [7:0] code_i; 
  reg set_i;

  wire ready_o; 
  wire cs_n; 
  wire miso;

  reg [7:0] sent_data;

  localparam T = 2;

  initial begin 
    sck = 0; 
    forever #1 begin 
      sck = ~sck; 
    end
  end

  initial begin 
    rst = 1; 
    code_i = 8'h8F;
    set_i = 0;

    #T; 
    rst = 0;

    #(T);

    set_i = 1; 

    #T;

    set_i = 0;

    for (int i = 0; i < 8; i++) begin 
      @(posedge sck) begin
        sent_data[7 - i] = miso;
      end
    end
    wait (ready_o == 1);

    #(10*T);

    $finish;
  end

  PgaInterface dut (
    .sck(sck), 
    .rst(rst), 
    .code_i(code_i), 
    .set_i(set_i), 
    .ready_o(ready_o),
    .cs_n(cs_n),
    .miso(miso)
  );
  
endmodule
