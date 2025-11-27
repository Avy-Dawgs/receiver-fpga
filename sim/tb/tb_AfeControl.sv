module tb_AfeControl(); 

  localparam T = 2;

  reg clk; 
  reg rst; 
  reg signed [7:0] gain_dB_i; 
  reg set_gain_i;
  reg pga_ready_i;

  wire [7:0] pga_code_o; 
  wire set_pga_o; 
  wire hga_bypass_o; 
  wire set_in_progress_o;

  initial begin 
    clk = 0; 
    forever #(T/2) begin 
      clk = ~clk;
    end
  end

  initial begin 
    rst = 1; 
    gain_dB_i = 0; 
    set_gain_i = 0; 
    pga_ready_i = 0;
    #T;
    rst = 0;

    #T;
    
    pga_ready_i = 1;

    wait(set_pga_o);
    #T;
    pga_ready_i = 0;

    #(10*T);
    pga_ready_i = 1;

    // wait for initial set to be done
    wait(!set_in_progress_o);
    #(T); 

    // pga only 
    set_gain_pga(.gain_dB(-8));

    // both inc 
    set_gain_pga(.gain_dB(64));

    // both dec
    set_gain_pga(.gain_dB(0));

    // hga only
    set_gain_no_pga(.gain_dB(40));

    $stop;

  end

  task automatic set_gain_pga (
    input logic signed [7:0] gain_dB
    );

    begin 
      gain_dB_i = gain_dB;
      set_gain_i = 1;
      #T; 
      pga_ready_i = 1;
      set_gain_i = 0;
      wait(set_pga_o);
      pga_ready_i = 0;
      #(10*T); 
      pga_ready_i = 1;
      wait(!set_in_progress_o);
      #T;
    end
  endtask

  task automatic set_gain_no_pga (
    input logic signed [7:0] gain_dB
    );
    begin 
      gain_dB_i = gain_dB;
      set_gain_i = 1; 
      #T; 
      set_gain_i = 0; 
      wait(!set_in_progress_o);
      #T;
    end 
  endtask

  AfeControl dut (
    .clk(clk), 
    .rst(rst), 
    .gain_dB_i(gain_dB_i), 
    .set_gain_i(set_gain_i), 
    .pga_code_o(pga_code_o),
    .set_pga_o(set_pga_o),
    .pga_ready_i(pga_ready_i),  
    .hga_bypass_o(hga_bypass_o), 
    .set_in_progress_o(set_in_progress_o)
  );

endmodule
