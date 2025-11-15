/*
* Goertzel Filter. 
* 
* Automatically scales.
*/
module GoertzelFilter 
#(
  signed COEFF,
  int COEFF_BITS,
  DW,
  BLOCK_SIZE_POW2,
  SCALE_BLOCK_SIZE_POW2
) 
(
  input clk, 
  input rst, 
  input clr_i,    // clear filter state
  input signed [DW - 1:0] data_i,   
  input valid_i,        
  output reg valid_o,
  output reg [BLOCK_SIZE_POW2 - 1:0] count_o,   // sample count
  output signed [DW + 2 - 1:0] s0_o, s1_o
);

  localparam OUTPUT_DW = DW + 2;
  
  // how many samples come in before scaling down
  localparam SCALE_COUNT = 2**SCALE_BLOCK_SIZE_POW2 - 1;
  // how many bits to scale down by
  localparam SCALE_SHIFT = SCALE_BLOCK_SIZE_POW2 - 1;

  localparam COEFF_FRAC_BITS = COEFF_BITS - 2;

  // data width is the input data width plus the scale block size bits plus
  // 1 bit padding
  localparam INTERNAL_DW = DW + SCALE_BLOCK_SIZE_POW2 + 1;

  // internal filter state registers
  reg signed [INTERNAL_DW - 1:0] s0_internal, s1_internal;

  reg signed [DW - 1:0] data_i_reg;
  reg signed [INTERNAL_DW - 1:0] coeff_product;

  /*
  * Multiply by the coefficient.
  */
  function automatic signed [INTERNAL_DW - 1:0] mult_coeff;
    input signed [INTERNAL_DW - 1:0] a;

    logic signed [INTERNAL_DW + COEFF_BITS - 1:0] acc;
    begin 
      acc = a * COEFF;
      return acc[INTERNAL_DW + COEFF_FRAC_BITS - 1:COEFF_FRAC_BITS];
    end
  endfunction

  /*
  * STATE MACHINE
  */

  typedef enum bit [1:0]
  {
    IDLE,   // waiting for sample
    UPDATE, // update filter state (have sample)
    SCALE   // scale down internal values
  } states_t;

  logic idle_to_update_transition; 
  logic update_to_scale_transition; 

  reg [1:0] state; 
  logic [1:0] next_state;

  // state transition
  always_ff @(posedge clk or posedge rst) begin 
    if (rst || clr_i) begin 
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
        next_state = IDLE; 
        if (idle_to_update_transition) begin 
          next_state = UPDATE; 
        end 
      end
      UPDATE: begin 
        next_state = IDLE; 
        if (update_to_scale_transition) begin 
          next_state = SCALE; 
        end
      end
      SCALE: begin 
        next_state = IDLE;
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  // state transitions
  assign idle_to_update_transition = valid_i;
  assign update_to_scale_transition = (count_o[SCALE_BLOCK_SIZE_POW2 - 1:0] == SCALE_COUNT);

  // count register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst || clr_i) begin 
      count_o <= 'h0;
    end
    else begin 
      if (valid_o) begin
        count_o <= count_o + 1'h1;
      end
    end
  end

  /*
  * FILTER LOGIC 
  */

  always_ff @(posedge clk or posedge rst) begin 
    if (rst || clr_i) begin 
      data_i_reg <= 'h0;
      coeff_product <= 'h0;
      s0_internal <= 'h0;
      s1_internal <= 'h0;
      valid_o <= 1'h0;
    end 
    else begin 
      case (state)
        IDLE: begin
          valid_o <= 1'h0;
          // register input, multiplication result
          if (valid_i) begin 
            data_i_reg <= data_i;
            coeff_product <= mult_coeff(s0_internal); 
          end
        end
        UPDATE: begin 
          // perform filter update, (register outputs)
          s0_internal <= {{INTERNAL_DW - DW{data_i_reg[DW - 1]}}, data_i_reg} + coeff_product - s1_internal;
          s1_internal <= s0_internal;

          // output is valid if scale doesn't need to happen
          if (!update_to_scale_transition) begin
            valid_o <= 1'h1;
          end
        end
        SCALE: begin 
          s0_internal <= s0_internal >>> SCALE_SHIFT; 
          s1_internal <= s1_internal >>> SCALE_SHIFT;
          valid_o <= 1'h1;
        end
        default: ;
      endcase
    end
  end

  assign s0_o = s0_internal[OUTPUT_DW - 1:0];
  assign s1_o = s1_internal[OUTPUT_DW - 1:0];

endmodule
