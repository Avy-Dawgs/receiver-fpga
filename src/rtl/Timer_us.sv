/*
* Microsecond timer.
*/
module Timer_us
#(
  CLK_FREQ, 
  TIME_US
) 
(
  input clk, 
  input rst, 
  input start_i, 
  input done_o
); 

  wire [$clog2(TIME_US) - 1:0] us_count;

  logic timer_done;
  logic clr_counter;

  /*
  * STATE MACHINE
  */

  typedef enum bit
  {
    IDLE, 
    RUNNING
  } states_t;

  reg state; 
  reg next_state; 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= IDLE;
    end
    else begin 
      state <= next_state;
    end
  end

  always_comb begin 
    case (state) 
      IDLE: begin
        next_state = IDLE; 
        if (start_i) begin 
          next_state = RUNNING;
        end
      end
      RUNNING: begin 
        next_state = RUNNING;
        if (timer_done) begin 
          next_state = IDLE;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      done_o <= 1'h0;
    end
    else begin 
      case (state) 
        IDLE: begin 
          done_o <= 1'h0;
        end
        RUNNING: begin 
          if (timer_done) begin 
            done_o <= 1'h1;
          end
        end
        default: begin 
          done_o <= 1'h0;
        end
      endcase
    end
  end


  assign timer_done = (us_count == TIME_US);
  assign clr_counter = (state == IDLE);


  Counter_us 
  #(
    .CLK_FREQ(CLK_FREQ), 
    .MAX_COUNT(TIME_US)
  )
  counter 
  (
    .clk(clk), 
    .rst(rst), 
    .clr_i(clr_counter),
    .count_o(us_count)
  );
  

endmodule
