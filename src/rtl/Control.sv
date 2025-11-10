/*
* Controls the signal chain, and the amplifier gain.
*/
module Control 
#(
  CLK_FREQ
)
(
  input clk, 
  input rst, 
  input [15:0] dB_i, 
  input valid_i,
  input ms_en_i,
  output datapath_en_o,   // will enable dc filter
  output goertzel_start_o, // starts goertzel block
  output hga_bypass_o,    // high gain amp enable (stage 1)
  output pga_code_o,  // TODO width
  output pga_set_o 
); 

  // how long to wait after changing HGA bypass
  localparam HGA_SET_SETTLE_TIME_US = 0;
  // how long to wait after setting PGA
  localparam PGA_SET_SETTLE_TIME_US = 0;

  // max count for pulse repetition interval
  localparam PRI_COUNTER_MAX_COUNT_MS = 1500;

  localparam SETTLE_TIMER_BITS = 10;

  logic clr_pri_count; 
  wire [$clog2(PRI_COUNTER_MAX_COUNT_MS) - 1:0] pri_count;

  logic start_settle_timer;
  logic clr_settle_timer;
  wire settle_timer_done;
  wire settle_timer_active;
  logic [SETTLE_TIMER_BITS - 1:0] settle_timer_target;

  wire ms_since_threshold;

  // set gain conditions: 
  // 1. gain lock timer is on
  // 2. signal is too high 
  // 3. signal has been below threshold for previous PRI 

  typedef enum {
    START_BLOCK,     // start the block (goertzel algorithm)
    BLOCK_WAIT,     // wait for end of goertzel algorithm
    CHECK_CONDITIONS,   // check conditions for setting gain
    CALC_GAIN,    // calculate new gain
    SET_GAIN,   // set gain
    SETTLE_WAIT     // wait for settle 
  } states_t;

  reg state; 
  logic next_state; 

  // state transition
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= START_BLOCK;
    end
    else begin 
      state <= next_state;
    end
  end

  // next state
  always_comb begin 
    case (state)
      START_BLOCK: begin 
        // goertzel algorithm is started in this state, always go 
        // to wait as next state
        next_state = BLOCK_WAIT;
      end
      BLOCK_WAIT: begin 
        // wait for the next valid piece of data
        next_state = valid_i ? CALC_GAIN : BLOCK_WAIT;
      end
      CALC_GAIN: begin 
        // start the next block unless gain needs to be set
        next_state = START_BLOCK;
        // TODO conditions
        if (1'h1) begin 
          next_state = SET_GAIN;
        end
      end
      SET_GAIN: begin 
        // wait for the gain to be finished setting, 
        // at which point the timer is started and the 
        // wait for afe to settle begins
        next_state = SET_GAIN;
        // TODO conditions
        if (1'h1) begin 
          next_state = SETTLE_WAIT;
        end
      end
      SETTLE_WAIT: begin
        // wait for the settle timer to complete
        next_state = settle_timer_done ? START_BLOCK : SETTLE_WAIT;
      end
      default: begin
        next_state = NULL;
      end
    endcase
  end

  // is signal below range for last PRI?
  assign signal_too_low = time_since_threshold > 'd1100;

  // is signal above range right now?
  assign signal_too_high = dB_i > 'd40;

  /*
  * MODULES
  */

  // look-up-table for gain

  // TODO is this needed
  Counter_ms #(
    .CLK_FREQ(CLK_FREQ),
    .MAX_COUNT(PRI_COUNTER_MAX_COUNT_MS)
  )
  pri_counter (
    .clk(clk), 
    .rst(rst), 
    .clr_i(clr_pri_count), 
    .count_o(pri_count)
  );

  // tracks the milliseconds since the signal was last above the 
  // threshold
  ThresholdTracker #(
    .DW(), 
    .MAX_TIME(), 
    .THRESHOLD()
    ) thres_tracker (
      .clk(clk), 
      .rst(rst), 
      .clr_i(),
      .tu_en(ms_en_i),
      .signal_i(dB_i),
      .valid_i(valid_i),
      .tu_since_threshold_o(ms_since_threshold)
    );

  // timer used to measure the settle time from setting the gain 
  // of the AFE
  Timer #(
    DW(SETTLE_TIMER_BITS)
    ) 
    settle_timer (
      .clk(clk), 
      .rst(rst), 
      .start_i(start_settle_timer), 
      .target_i(settle_timer_target),
      .en_i(ms_en_i),   
      .clr_i(clr_settle_timer), 
      .done_o(settle_timer_done), 
      .active_o(settle_timer_active)
    );

endmodule
