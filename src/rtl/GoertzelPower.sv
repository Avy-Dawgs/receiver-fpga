/*
* Calculates magnitude at selected frequency using Goertzel algorithm.
*
* must be explicitely started via start_i
*/
module GoertzelPower 
#(
  real FREQ, 
  int SIZE, 
  real SAMP_RATE, 
  int FRAC_BITS
) 
(
  input clk,
  input rst,
  input start_i,
  input signed [15:0] data_i, 
  input valid_i, 
  output reg done_o,
  output reg [31:0] power_o
); 

  /*
  * PARAMETERS 
  */

  localparam COEFF_BITS = 24;

  localparam real PI = 3.141592653589763;

  localparam SCALE_SHIFT = $clog2(SIZE/2);
  localparam real OMEGA = 2 * PI * $floor(0.5 + SIZE * FREQ / SAMP_RATE) / SIZE;
  localparam signed [31:0] SINE = $rtoi($sin(OMEGA) * 2**COEFF_BITS); 
  localparam signed [31:0] COSINE = $rtoi($cos(OMEGA) * 2**COEFF_BITS);
  localparam signed [31:0] COEFF = 2 * COSINE;

  /*
  * REGISTERS / WIRES 
  */

  reg [$clog2(SIZE) - 1:0] count;

  reg signed [31:0] s0_reg, s1_reg;
  wire signed [31:0] filter_s0, filter_s1;

  reg signed [31:0] im_reg, re_reg;
  logic signed [31:0] im_noscale, re_noscale;

  wire filter_valid; 
  logic clr_filter;

  logic last_sample_ready;

  /*
  * FUNCTIONS
  */

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

  typedef enum bit[1:0] {
    IDLE,     // wait for start
    FILTER,   // filtering stream
    IM_RE_CALC, // calculate IM and RE components
    POW_CALC  // calculate power
  } states_t;

  reg [1:0] state;
  logic [1:0] next_state;

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
      IDLE: 
        if (start_i) begin 
          next_state = FILTER;
        end
        else begin 
          next_state = IDLE;
        end
      FILTER: 
        if (last_sample_ready) begin 
          next_state = IM_RE_CALC; 
        end
        else begin 
          next_state = FILTER; 
        end
      IM_RE_CALC: 
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

  // count samples output from filter
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      count <= 'h0;
    end
    else begin 
      case (state) 
        FILTER: 
          if (filter_valid) begin 
            count <= count + 1'h1;
          end
        default: 
          count <= 'h0;
      endcase
    end
  end

  // power calc logic
  always_ff @(posedge clk or posedge rst) begin 
    if (rst) begin 
      s0_reg <= 'h0;
      s1_reg <= 'h0;
      re_reg <= 'h0;
      im_reg <= 'h0;
      power_o <= 'h0;
      done_o <= 1'h0;
    end
    else begin 
      case (state) 
        IDLE: begin 
          s0_reg <= 'h0;
          s1_reg <= 'h0;
          done_o <= 1'h0;
        end
        FILTER: 
          // sample filter registers when last sample is ready
          if (last_sample_ready) begin 
            s0_reg <= filter_s0;
            s1_reg <= filter_s1;
          end
        IM_RE_CALC: begin 
          re_reg <= re_noscale >>> (FRAC_BITS + SCALE_SHIFT);
          im_reg <= im_noscale >>> (FRAC_BITS + SCALE_SHIFT);
        end
        POW_CALC: begin 
          power_o <= im_reg*im_reg + re_reg*re_reg;
          done_o <= 1'h1;
        end
        default: ;
      endcase
    end
  end

  /*
  * COMBINATIONAL 
  */

  assign last_sample_ready = (count == (SIZE - 1)) && filter_valid;
  assign clr_filter = (state != FILTER);

  assign re_noscale = mult_coeff(s0_reg, COSINE) - s1_reg;
  assign im_noscale = mult_coeff(s0_reg, SINE);

  /*
  * MODULES 
  */

  GoertzelFilter 
  #(
    .COEFF(COEFF), 
    .COEFF_BITS(COEFF_BITS)
  ) 
  filter 
  (
    .clk(clk), 
    .rst(rst), 
    .clr(clr_filter), 
    .data_i(data_i), 
    .valid_i(valid_i), 
    .valid_o(filter_valid), 
    .s0(filter_s0), 
    .s1(filter_s1)
  );

endmodule
