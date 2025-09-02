/*
* Log2 algorithm with pipelined architecture. 
* 
* Uses a leading one extractor and a mantissa LUT.
*/
module Log2
#(
  DW = 32, 
  FRAC_BITS = 8
)
(
  input clk, 
  input rst,
  input valid_i,
  input [DW-1:0] x,
  output reg [$clog2(DW-1) + FRAC_BITS - 1:0] log2,
  output reg valid_o
);

  reg x_reg_valid;
  reg leading_one_idx_reg_valid; 

  reg [DW - 1:0] x_reg;
  logic [DW + $clog2(DW - 1) - 1:0] x_reg_ext;
  logic [DW - 1:0] x_reg_ext_sh;

  logic [$clog2(DW-1) - 1:0] leading_one_idx;
  reg [$clog2(DW-1) - 1:0] leading_one_idx_reg;

  reg [FRAC_BITS - 1:0] lin_mantissa_reg;
  logic [FRAC_BITS - 1:0] lin_mantissa;
  logic [FRAC_BITS - 1:0] log2_mantissa;

  reg [FRAC_BITS - 1:0] log2_mantissa_lut [0:2**FRAC_BITS - 1];
  initial begin 
    for (int i = 0; i < 2**FRAC_BITS; i++) begin 
      log2_mantissa_lut[i] = $rtoi($log10(1.0 + real'(i)/2.0**FRAC_BITS)/$log10(2) * 2.0**FRAC_BITS);
    end
  end

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin 
      x_reg_valid <= 1'h0;
      leading_one_idx_reg_valid <= 1'h0;
      valid_o <= 1'h0;
    end
    else begin 
      x_reg_valid <= valid_i;
      leading_one_idx_reg_valid <= x_reg_valid;
      valid_o <= leading_one_idx_reg_valid;
    end
  end

  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      x_reg <= 'h0; 
      leading_one_idx_reg <= 'h0;
      lin_mantissa_reg <= 'h0;
      log2 <= 'h0;
    end
    else begin 
      // register input
      x_reg <= x;
      // register leeading one, register linear mantissa
      leading_one_idx_reg <= leading_one_idx;
      lin_mantissa_reg <= lin_mantissa;
      // assemble and register output
      log2 <= {leading_one_idx_reg, log2_mantissa};
    end
  end

  // priority encoder to find the leading 1
  always_comb begin
    leading_one_idx = 'h0;
    for (int i = 0; i < 32; i++) begin 
      if (x_reg[i]) begin 
        leading_one_idx = i;
      end
    end
  end

  assign x_reg_ext = {x_reg, {FRAC_BITS{1'h0}}};            
  assign x_reg_ext_sh = x_reg_ext >> leading_one_idx;   
  assign lin_mantissa = x_reg_ext_sh[FRAC_BITS - 1:0];
  assign log2_mantissa = log2_mantissa_lut[lin_mantissa_reg];

endmodule
