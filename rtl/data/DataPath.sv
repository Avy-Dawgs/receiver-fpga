/*
* Datapath, including conversion to dB.
*/
module DataPath (
  input clk, 
  input rst, 
  input [11:0] data_i,
  input valid_i, 
  output [15:0] data_o, 
  output valid_o
  ); 

  wire [17:0] re, im; 
  wire reim_valid;

  wire [18:0] power; 
  wire power_valid;

  Signal_Chain sigchain_i (
    .clk(clk), 
    .rst(rst), 
    .clk_en(1'h1), 
    .data_i(data_i), 
    .valid_i(valid_i), 
    .ce_out(), 
    .data_o_re(re), 
    .data_o_im(im),
    .valid_o(reim_valid)
  );

  Complex2Power #(
    .DW(18), 
    .QBITS(16)
    ) comp2pow (
      .clk(clk), 
      .rst(rst), 
      .data_i_re(re), 
      .data_i_im(im), 
      .valid_i(reim_valid), 
      .power_o(power), 
      .valid_o(power_valid)
    );

  PowerToDB pow2db (
    .clk(clk), 
    .rst(rst), 
    .power_i(power >> 3), 
    .valid_i(power_valid), 
    .dB_o(data_o), 
    .valid_o(valid_o)
  );

endmodule
