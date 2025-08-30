/*
* Simple DC blocking filter. 
*
* en_i signal disables filter operation and thus updates to internal state
*/
module DcBlocker
#(
  INPUT_DW, 
  INTERNAL_FRAC_BITS, 
  OUTPUT_FRAC_BITS
)
(
  input clk, 
  input rst, 
  input [INPUT_DW - 1:0] data_i, 
  input en_i,
  input valid_i, 
  output reg valid_o, 
  output signed [INPUT_DW + OUTPUT_FRAC_BITS:0] data_o
); 

  // add one bit as the sign because input is an unsigned number
  localparam INTERNAL_DW = INPUT_DW + INTERNAL_FRAC_BITS + 1; 

  // leave one bit for sign
  localparam ALPHA_FRAC_BITS = INTERNAL_DW - 1;
  localparam real ALPHA_REAL = 0.99;
  localparam signed [INTERNAL_DW - 1:0] ALPHA  = $rtoi(ALPHA_REAL * 2.0**ALPHA_FRAC_BITS);

  logic signed [INTERNAL_DW * 2 - 1:0] alpha_mult_acc; 
  logic signed [INTERNAL_DW - 1:0] alpha_mult_scaled;
  reg signed [INTERNAL_DW - 1:0] alpha_mult_scaled_reg;

  logic signed [INTERNAL_DW - 1:0] data_i_ext;
  reg signed [INTERNAL_DW - 1:0] x0_reg, x1_reg;
  reg signed [INTERNAL_DW - 1:0] y0_reg;

  logic update_transition;

  typedef enum 
  {
    IDLE, 
    UPDATE
  } states_t;

  reg state; 
  logic next_state; 

  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      state <= IDLE; 
    end
    else begin 
      state <= next_state;
    end
  end

  always_comb begin 
    case (state) 
      IDLE: 
        if (update_transition) begin 
          next_state = UPDATE;
        end
        else begin 
          next_state = IDLE;
        end
      default: 
        next_state = IDLE;
    endcase
  end

  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      x0_reg <= 'h0;
      x1_reg <= 'h0;
      y0_reg <= 'h0;
      alpha_mult_scaled_reg <= 'h0;
      valid_o <= 1'h0;
    end
    else begin 
      case (state) 
        IDLE: begin
          valid_o <= 1'h0;
          if (update_transition) begin 
            // register input, register multiplication result
            x0_reg <= data_i_ext;
            alpha_mult_scaled_reg <= alpha_mult_scaled;
          end
        end
        UPDATE: begin 
          // update and register output
          y0_reg <= x0_reg - x1_reg + alpha_mult_scaled_reg;
          x1_reg <= x0_reg;
          valid_o <= 1'h1;
        end
        default: ;
      endcase
    end
  end

  assign update_transition = valid_i && en_i;

  assign data_i_ext = {1'h0, data_i, {INTERNAL_FRAC_BITS{1'h0}}};

  assign alpha_mult_acc = y0_reg * ALPHA;
  assign alpha_mult_scaled = alpha_mult_acc >>> ALPHA_FRAC_BITS;

  assign data_o = y0_reg >>> (INTERNAL_FRAC_BITS - OUTPUT_FRAC_BITS);

endmodule
