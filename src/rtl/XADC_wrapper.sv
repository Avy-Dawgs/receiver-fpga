/*
* Simple wrapper for XADC to only convert one channel.
*/
module XADC_wrapper 
(
  input clk,
  input rst,
  input vauxp5, 
  input vauxn5, 
  output [11:0] data_o,
  output valid_o
);

wire drdy_out; 
wire [15:0] do_out; 
wire eoc_out; 

assign data_o = do_out[15:4];  
assign valid_o = drdy_out;   // pass along data ready

XADC_wiz xadc_i (
  .di_in(1'h0),              // input wire [15 : 0] di_in
  .daddr_in(6'h15),        // input wire [6 : 0] daddr_in
  .den_in(eoc_out),            // input wire den_in
  .dwe_in(1'h0),            // input wire dwe_in
  .drdy_out(drdy_out),        // output wire drdy_out
  .do_out(do_out),            // output wire [15 : 0] do_out
  .dclk_in(clk),          // input wire dclk_in
  .reset_in(rst),        // input wire reset_in
  .vp_in(),              // input wire vp_in
  .vn_in(),              // input wire vn_in
  .vauxp5(vauxp5),            // input wire vauxp5
  .vauxn5(vauxn5),            // input wire vauxn5
  .channel_out(),  // output wire [4 : 0] channel_out
  .eoc_out(eoc_out),          // output wire eoc_out
  .alarm_out(),      // output wire alarm_out
  .eos_out(),          // output wire eos_out
  .busy_out()        // output wire busy_out
);

endmodule
