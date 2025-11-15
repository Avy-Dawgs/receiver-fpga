/*
* Converts power to dB. Uses pipelined architecture.
* 
* Takes log10 via log2 then change of base formula.
*/
module PowerToDB 
(
  input clk, 
  input rst, 
  input valid_i,
  input [31:0] power_i, 
  output reg [15:0] dB_o,
  output reg valid_o
  ); 

  localparam COEFF_FRAC_BITS = 20;

  localparam RECIP_LOG2_10 = $rtoi(1.0/($log10(10.0)/$log10(2.0)) * 2.0**COEFF_FRAC_BITS);

  wire [12:0] log2; 
  reg [12:0] log2_reg;
  reg log2_reg_valid;
  wire log2_valid;

  logic [15 + COEFF_FRAC_BITS:0] log10_acc;
  logic [15:0] log10;
  reg [15:0] log10_reg; 
  reg log10_reg_valid; 

// steps: 
//  - log2(x) registers input
//  - wait for log2(x) and register result
//  - multiply result by 1/log2(10) 
//  - multiply result by 10 and register output

  // calculation registers
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      log2_reg <= 'h0;
      log10_reg <= 'h0;
      dB_o <= 'h0;
    end
    else begin 
      log2_reg <= log2;
      log10_reg <= log10; 
      dB_o <= 10 * log10_reg;
    end
  end

  // valid registers
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      log2_reg_valid <= 'h0;
      log10_reg_valid <= 'h0;
      valid_o <= 'h0;
    end
    else begin 
      log2_reg_valid <= log2_valid; 
      log10_reg_valid <= log2_reg_valid; 
      valid_o <= log10_reg_valid;
    end
  end

  // multiplication by the reciprical (with accumulation)
  assign log10_acc = log2_reg * RECIP_LOG2_10;
  // final log10 value calculation
  assign log10 = log10_acc >> COEFF_FRAC_BITS;

  Log2 
  #(
    .DW(32), 
    .FRAC_BITS(8)
  )
  log2_inst
  (
    .clk(clk), 
    .rst(rst), 
    .valid_i(valid_i), 
    .x(power_i), 
    .log2(log2), 
    .valid_o(log2_valid)
  );

endmodule
