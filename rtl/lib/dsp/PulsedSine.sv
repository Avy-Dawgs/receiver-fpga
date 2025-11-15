/*
* Generate a pulse sine wave.
*/
module PulsedSine
#(
  CLK_FREQ,
  FREQ, 
  SAMP_RATE,
  PW_MS, 
  PRI_MS,
  DW
)
(
  input clk, 
  input rst, 
  output [DW - 1:0] data_o, 
  output valid_o
); 

  localparam LUT_ADDR_BITS = 8;
  localparam LUT_FRAC_BITS = DW - 1;

  localparam LUT_SIZE = 2**LUT_ADDR_BITS;

  localparam ADDR_FRAC_BITS = 4;

  localparam real SAMPLES_PER_PERIOD = SAMP_RATE / FREQ;
  localparam INC_PER_SAMPLE = $rtoi(real'(LUT_SIZE) / SAMPLES_PER_PERIOD * 2.0**ADDR_FRAC_BITS);

  reg [LUT_ADDR_BITS + ADDR_FRAC_BITS - 1:0] lut_addr_ext;
  logic [LUT_ADDR_BITS - 1:0] lut_addr;

  wire sample_en;
  wire [DW - 1:0] lut_sample;

  wire [$clog2(PRI_MS) - 1:0] count;

  /*
  * STATE MACHINE
  */

  typedef enum bit 
  {
    OFF, 
    ON
  } states_t;

  reg state; 
  logic next_state; 

  logic on_to_off_transition; 
  logic off_to_on_transition;

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= ON;
    end
    else begin 
      state <= next_state;
    end
  end

  always_comb begin 
    case (state)
      ON: begin 
        next_state = ON;
        if (on_to_off_transition) begin 
          next_state = OFF;
        end
      end
      OFF: begin 
        next_state = OFF;
        if (off_to_on_transition) begin 
          next_state = ON;
        end
      end
      default: begin 
        next_state = ON;
      end
    endcase
  end

  assign on_to_off_transition = (count == PW_MS);
  assign off_to_on_transition = (count == PRI_MS);

  /*
  * SEQUENTIAL
  */

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      lut_addr_ext <= 'h0;
    end
    else begin 
      if (sample_en) begin 
        lut_addr_ext <= lut_addr_ext + INC_PER_SAMPLE;
      end
    end
  end

  /*
  * COMBINATIONAL
  */

  assign data_o = (state == ON) ? lut_sample : 'h0;

  assign valid_o = sample_en;

  assign lut_addr = lut_addr_ext >> ADDR_FRAC_BITS;

  /*
  * MODULES
  */
  
  // enable signal at sample rate 
  EnableGenerator
  #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(SAMP_RATE)
  ) 
  sample_en_gen
  (
    .clk(clk), 
    .rst(rst), 
    .en_o(sample_en)
  );

  SineLut 
  #(
    .ADDR_BITS(LUT_ADDR_BITS), 
    .FRAC_BITS(LUT_FRAC_BITS)
  ) 
  sine_lut
  (
    .clk(clk), 
    .rst(rst), 
    .addr_i(lut_addr), 
    .sample_o(lut_sample)
  );

  Counter_ms 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .MAX_COUNT(PRI_MS)
  ) 
  pri_counter
  (
    .clk(clk), 
    .rst(rst), 
    .clr_i(1'h0), 
    .count_o(count)
  );

endmodule
