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
  output reg valid_o
); 

  localparam LUT_ADDR_BITS = 8;

  wire sample_en;
  wire lut_sample;

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
      
    end
    else begin 
      
    end
  end

  /*
  * COMBINATIONAL
  */

  assign data_o = (state == ON) ? lut_sample : 'h0;

  /*
  * MODULES
  */
  
  // enable signal at sample rate 
  EnableGenerator
  #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(FREQ)
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
    .DW(DW)
  ) 
  sine_lut
  (
    .clk(clk), 
    .rst(rst), 
    .addr_i(), 
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
