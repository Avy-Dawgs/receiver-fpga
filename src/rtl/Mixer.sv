/*
* Mixer producing an interleaved stream of 
* real and imag data.
*/
module Mixer #(
  DW, 
  SAMP_RATE, 
  FREQ,
  LUT_ABITS
  ) (
  input clk, 
  input rst, 
  input signed [DW - 1:0] data_i, 
  input valid_i,
  input ready_i,
  output reg signed [DW - 1:0] data_o,
  output reg valid_o,
  output reg last_o
  ); 

  localparam LUT_QBITS = DW - 1;
  localparam PHASE_QBITS = 4;
  localparam PHASE_BITS = LUT_ABITS + PHASE_QBITS;
  localparam QUARTER_PHASE = (2**PHASE_BITS) >> 2;

  localparam real PHASE_INC_REAL = real'(2**LUT_ABITS) * real'(FREQ)/real'(SAMP_RATE);
  localparam PHASE_INC = $rtoi(PHASE_INC_REAL * real'(2**PHASE_QBITS));

  // 1. register input 
  // 2. multiply by sin 
  // 3. multiply by cos

  logic signed [2*DW - 1:0] acc;     // multiply acc
  reg signed [DW - 1:0] data_reg;  // input data reg

  wire signed [DW - 1:0] osc;     // oscillator 

  reg [PHASE_BITS - 1:0] phase_reg; 
  logic [PHASE_BITS - 1:0] phase;
  logic [LUT_ABITS - 1:0] addr;

  /***************** 
  * STATE MACHINE 
  * ***************/ 

  typedef enum {
    IDLE,           // wait for input valid
    SIN_MULT,       // multiply by sin
    SIN_OUT_WAIT,   // wait for output to be transferred
    COS_MULT,       // multiply by cos
    COS_OUT_WAIT    // wait for output to be transferred
    } states_t;

    reg [2:0] state; 
    logic [2:0] next_state; 

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
          next_state = valid_i ? SIN_MULT : IDLE;
        end
        SIN_MULT: begin 
          next_state = SIN_OUT_WAIT;
        end
        SIN_OUT_WAIT: begin 
          next_state = ready_i ? COS_MULT : SIN_OUT_WAIT;
        end
        COS_MULT: begin 
          next_state = COS_OUT_WAIT;
        end
        COS_OUT_WAIT: begin 
          next_state = ready_i ? IDLE : COS_OUT_WAIT;
        end
        default: begin 
          next_state = IDLE;
        end
      endcase
    end

    /********************
    * SEQUENTIAL
    * ******************/ 

  // input data reg
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      data_reg <= 'h0;
    end
    else begin 
      if ((state == IDLE) && valid_i) begin 
        data_reg <= data_i;
      end
    end
  end

  // outputs 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      valid_o <= 1'h0;
      last_o <= 1'h0;
    end
    else begin 
      case (state) 
        SIN_OUT_WAIT: begin
          valid_o <= 1'h1;
          last_o <= 1'h0;
        end 
        COS_OUT_WAIT: begin 
          valid_o <= 1'h1;
          last_o <= 1'h1;
        end
        default: begin 
          valid_o <= 1'h0;
          last_o <= 1'h0;
        end
      endcase
    end
  end

  // calculations 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      data_o <= 'h0;
    end
    else begin 
      if ((state == SIN_MULT) || (state == COS_MULT)) begin 
        data_o <= acc >>> LUT_QBITS;
      end
    end
  end

  // phase register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      phase_reg <= 'h0;
    end 
    else begin 
      // values have all been calculated, inc phase
      if (state == COS_OUT_WAIT) begin 
        phase_reg <= phase_reg + PHASE_INC;
      end
    end 
  end

  /*************** 
  * COMBINATIONAL 
  * *************/ 

  always_comb begin 
    case (state) 
      // this state is one before COS is needed, 
      // so we can subract a quarter of phase here
      SIN_OUT_WAIT: begin 
        phase = phase_reg - QUARTER_PHASE;
      end
      default: begin 
        phase = phase_reg;
      end
    endcase
  end

  assign acc = data_reg * osc;
  assign addr = phase[PHASE_QBITS +: LUT_ABITS];

  /*************** 
  * MODULES 
  * *************/

  // oscillator (LUT)
  SineLut #(
    .ABITS(LUT_ABITS), 
    .QBITS(LUT_QBITS)
    ) sine_osc (
      .clk(clk), 
      .rst(rst), 
      .addr_i(addr), 
      .sample_o(osc)
    );

endmodule
