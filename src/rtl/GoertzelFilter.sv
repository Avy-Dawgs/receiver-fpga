/*
* Goertzel Filter.
*/
module GoertzelFilter 
#(
  signed COEFF,
  int COEFF_BITS
) 
(
  input clk, 
  input rst, 
  input clr,
  input signed [15:0] data_i, 
  input valid_i, 
  output reg valid_o,
  output reg signed [31:0] s0, s1
);

  reg signed [15:0] data_i_reg;
  reg signed [31:0] mult_res_reg;

  function automatic signed [31:0] mult_coeff;
    input signed [31:0] a, b;

    logic signed [63:0] acc;
    begin 
      acc = a * b;
      return acc[31 + COEFF_BITS:COEFF_BITS];
    end
  endfunction

  /*
  * STATE MACHINE
  */

  typedef enum 
  {
    IDLE, 
    COMP 
  } states_t;

  reg state; 
  logic next_state;

  always_ff @(posedge clk or posedge rst) begin 
    if (rst || clr) begin 
      state <= IDLE;
    end 
    else begin 
      state <= next_state;
    end
  end

  always_comb begin 
    case (state) 
      IDLE: 
        if (valid_i) begin 
          next_state = COMP; 
        end 
        else begin 
          next_state = IDLE; 
        end
      default:
        next_state = IDLE;
    endcase
  end

  /*
  * FILTER LOGIC 
  */

  always_ff @(posedge clk or posedge rst) begin 
    if (rst || clr) begin 
      data_i_reg <= 'h0;
      mult_res_reg <= 'h0;
      s0 <= 'h0;
      s1 <= 'h0;
      valid_o <= 1'h0;
    end 
    else begin 
      case (state)
        IDLE: begin
          valid_o <= 1'h0;
          // register input, multiplication result
          if (valid_i) begin 
            data_i_reg <= data_i;
            mult_res_reg <= mult_coeff(s0, COEFF); 
          end
        end
        COMP: begin 
          // perform filter update, (register outputs)
          s0 <= {{16{data_i_reg[15]}}, data_i_reg} + mult_res_reg - s1;
          s1 <= s0;
          valid_o <= 1'h1;
        end
        default: ;
      endcase
    end
  end

endmodule
