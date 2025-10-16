/*
* Convertes complex to magnitude squared.
*/
module Comp2MagSqrd #(
  DW
  ) (
  input clk, 
  input rst, 
  input [DW - 1:0] real_i, 
  input [DW - 1:0] imag_i, 
  input valid_i,
  output reg [2*DW - 1:0] mag_sqrd_o,
  output valid_o
  ); 

  // 1. register inputs 
  // 2. square real 
  // 3. square imag and add 
  // 4. register output

  reg [DW - 1:0] real_reg;
  reg [DW - 1:0] imag_reg;

  // multiplier
  logic [DW - 1:0] sq_in; 
  logic [2*DW - 1:0] sq; 

  /**************** 
  * STATE MACHINE
  * **************/

  typedef enum {
    IDLE, 
    SQ_RE, 
    SQ_IM 
  } states_t;

  reg [1:0] state; 
  logic [1:0] next_state;

  // state transition
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= IDLE;
    end
    else begin 
      state <= next_state;
    end
  end

  // next state
  always_comb begin 
    case (state) 
      IDLE: begin 
        next_state = valid_i ? SQ_RE : SQ_IM;
      end
      SQ_RE: begin 
        next_state = SQ_IM;
      end
      SQ_IM: begin 
        next_state = IDLE;
      end
      default: begin 
        next_state = IDLE;
      end
    endcase
  end

  /******************** 
  * Sequential 
  * ******************/

  // input registers
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      real_reg <= 'h0;
      imag_reg <= 'h0;
    end
    else begin 
      if ((state == IDLE) && valid_i) begin 
        real_reg <= real_i; 
        imag_reg <= imag_i;
      end
    end
  end

  // output register 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      mag_sqrd_o <= 'h0; 
      valid_o <= 1'h0;
    end 
    else begin 
      case (state) 
        SQ_RE: begin 
          mag_sqrd_o <= sq;
        end
        SQ_IM: begin 
          mag_sqrd_o <= mag_sqrd_o + sq;
          valid_o <= 1'h1;
        end
        default: begin 
          valid_o <= 1'h0;
        end
      endcase
    end
  end

  // select input to square multiplier
  always_comb begin 
    case (state)
      SQ_IM: begin 
        sq_in = imag_reg;
      end
      default: begin 
        sq_in = real_reg;
      end
    endcase
  end

  assign sq = sq_in * sq_in;

endmodule
