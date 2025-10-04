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
  input [15:0] power_i, 
  input valid_i,
  output dc_block_en_o, 
  output goertzel_start_o, 
  output hga_bypass_o,    // high gain amp enable (stage 1)
  output pga_gain_o   // TODO width
); 
  
  // how long to wait after changing HGA
  localparam HGA_SET_SETTLE_TIME_US = 0;
  // how long to wait after setting PGA
  localparam PGA_SET_SETTLE_TIME_US = 0;

  localparam PRI_COUNTER_MAX_COUNT_MS = 1500;

  logic clr_pri_count; 
  wire [$clog2(PRI_COUNTER_MAX_COUNT_MS) - 1:0] pri_count;

  logic start_pga_settle_timer; 
  logic start_hga_settle_timer; 
  wire pga_settle_timer_done; 
  wire hga_settle_timer_done;

  typedef enum {
    IDLE, 
    EVAL_GAIN, // evaluate gain
    SET_PGA, // set pga gain only
    SET_HGA,  // set hga gain only
    SET_HGA_AND_PGA, // set hga and pga gain
    SETTLE_WAIT     // wait for settle 
  } states_t;

  reg state; 
  logic next_state; 

  // state transition
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= 'h0;
    end
    else begin 
      state <= next_state;
    end
  end

  // next state
  always_comb begin 
    case (state)
      default: begin
        next_state = 'h0;
      end
    endcase
  end


  /*
  * MODULES
  */

  // pulse repetition interval counter 
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

  // TODO: merge these timers

  // HGA settle time timer
  Timer_us #(
    .CLK_FREQ(CLK_FREQ), 
    .TIME_US(HGA_SET_SETTLE_TIME_US)
    )
    hga_settle_timer (
      .clk(clk), 
      .rst(rst), 
      .start_i(start_hga_settle_timer), 
      .done_o(hga_settle_timer_done)
    );

  Timer_us #(
    .CLK_FREQ(CLK_FREQ), 
    .TIME_US(PGA_SET_SETTLE_TIME_US)
  )
  pga_settle_timer (
    .clk(clk), 
    .rst(rst), 
    .start_i(start_pga_settle_timer), 
    .done_o(pga_settle_timer_done)
  );

endmodule
