/*
* Calculates magnitude at selected frequency using Goertzel algorithm.
*
* must be explicitely started via start_i
*/
module GoertzelPower 
#(
  real FREQ, 
  int SIZE_POW2, 
  real SAMP_RATE, 
  int FRAC_BITS, 
  DW
) 
(
  input clk,
  input rst,
  input start_i,
  input signed [DW - 1:0] data_i, 
  input valid_i, 
  output reg done_o,
  output reg [DW * 2 - 1:0] power_o
); 

  /*
  * PARAMETERS 
  */

  localparam INTERNAL_DW = DW + 2;

  localparam COEFF_BITS = 24;
  localparam SCALE_BLOCK_SIZE_POW2 = 8;

  localparam MAX_COUNT = 2**SIZE_POW2 - 1;

  localparam real PI = 3.141592653589763;

  localparam COEFF_FRAC_BITS = COEFF_BITS - 2;

  localparam real SIZE = 2**SIZE_POW2;
  localparam real OMEGA = 2.0 * PI * $floor(0.5 + real'(SIZE) * FREQ / SAMP_RATE) / real'(SIZE);
  localparam signed [COEFF_BITS - 1:0] SINE = $rtoi($sin(OMEGA) * 2.0**(COEFF_FRAC_BITS)); 
  localparam signed [COEFF_BITS - 1:0] COSINE = $rtoi($cos(OMEGA) * 2.0**(COEFF_FRAC_BITS));
  localparam signed [COEFF_BITS - 1:0] COEFF = 2 * COSINE;

  /*
  * REGISTERS / WIRES 
  */

  wire [SIZE_POW2 - 1:0] filter_count;

  reg signed [INTERNAL_DW - 1:0] s0_im, s1_re;
  wire signed [INTERNAL_DW - 1:0] filter_s0, filter_s1;

  reg signed [INTERNAL_DW*2 - 1:0] im_sq, re_sq;
  logic signed [INTERNAL_DW - 1:0] im_noscale, re_noscale;

  wire filter_valid; 
  logic clr_filter;

  logic last_sample_ready;

  /*
  * FUNCTIONS
  */

  function automatic signed [INTERNAL_DW - 1:0] mult_coeff;
    input signed [INTERNAL_DW - 1:0] a; 
    input signed [COEFF_BITS - 1:0] coeff;

    logic signed [INTERNAL_DW + COEFF_BITS - 1:0] acc;
    begin 
      acc = a * coeff;
      return acc[INTERNAL_DW + COEFF_FRAC_BITS - 1:COEFF_FRAC_BITS];
    end
  endfunction

  /*
  * STATE MACHINE
  */

  typedef enum bit[2:0] {
    IDLE,     // wait for start
    FILTER,   // filtering stream
    IM_RE_CALC, // calculate IM and RE components
    IM_RE_SQ,   // square IM and RE
    POW_CALC  // calculate power
  } states_t;

  reg [2:0] state;
  logic [2:0] next_state;

  always_ff @(posedge clk or posedge rst) begin 
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
        next_state = IDLE;
        if (start_i) begin 
          next_state = FILTER;
        end
      end
      FILTER: begin
        next_state = FILTER;
        if (last_sample_ready) begin 
          next_state = IM_RE_CALC; 
        end
      end
      IM_RE_CALC: 
        next_state = IM_RE_SQ;
      IM_RE_SQ: 
        next_state = POW_CALC;
      POW_CALC:
        next_state = IDLE;
      default: 
        next_state = IDLE;
    endcase
  end

  /* 
  * SEQUENTIAL
  */

  // power calc logic
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      s0_im <= 'h0;
      s1_re <= 'h0;
      re_sq <= 'h0;
      im_sq <= 'h0;
      power_o <= 'h0;
      done_o <= 1'h0;
    end
    else begin 
      case (state) 
        IDLE: begin 
          s0_im <= 'h0;
          s1_re <= 'h0;
          done_o <= 1'h0;
        end
        FILTER: 
          // sample filter registers when last sample is ready
          if (last_sample_ready) begin 
            s0_im <= filter_s0;
            s1_re <= filter_s1;
          end
        IM_RE_CALC: begin
          s0_im <= im_noscale >>> FRAC_BITS;
          s1_re <= re_noscale >>> FRAC_BITS;
        end
        IM_RE_SQ: begin 
          im_sq <= s0_im * s0_im;
          re_sq <= s1_re * s1_re;
        end
        POW_CALC: begin 
          power_o <= im_sq + re_sq;
          done_o <= 1'h1;
        end
        default: ;
      endcase
    end
  end

  /*
  * COMBINATIONAL 
  */

  assign last_sample_ready = (filter_count == MAX_COUNT) && filter_valid;
  assign clr_filter = (state != FILTER);

  assign re_noscale = mult_coeff(s0_im, COSINE) - s1_re;
  assign im_noscale = mult_coeff(s0_im, SINE);

  /*
  * MODULES 
  */

  GoertzelFilter 
  #(
    .COEFF(COEFF), 
    .COEFF_BITS(COEFF_BITS), 
    .DW(DW), 
    .BLOCK_SIZE_POW2(SIZE_POW2), 
    .SCALE_BLOCK_SIZE_POW2(SCALE_BLOCK_SIZE_POW2)
  ) 
  filter 
  (
    .clk(clk), 
    .rst(rst), 
    .clr_i(clr_filter), 
    .data_i(data_i), 
    .valid_i(valid_i), 
    .valid_o(filter_valid), 
    .count_o(filter_count),
    .s0_o(filter_s0), 
    .s1_o(filter_s1)
  );

endmodule
