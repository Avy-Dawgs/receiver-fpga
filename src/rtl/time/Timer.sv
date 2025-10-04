/*
* Timer with loadable count.
*/
module Timer #(
  DW
)
(
  input clk, 
  input rst, 
  input start_i,  // load target and start
  input [DW - 1:0] target_i, // target count
  input en_i,   // enable defining a time unit
  input clr_i,  // clear the counter
  output done_o,  // counter is finished
  output active_o // is counter active?
);

reg [DW - 1:0] count; 
reg [DW - 1:0] target;

logic target_reached;

reg state; 
logic next_state; 

typedef enum bit {
  IDLE, 
  ACTIVE
} states_t;

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
      next_state = start_i ? ACTIVE :  IDLE;
    end
    ACTIVE: begin 
      next_state = ACTIVE;
      if (target_reached || clr_i) begin
        next_state = IDLE;
      end
    end
  endcase
end

// target register
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    target <= 'h0;
  end
  else begin 
    if ((state == IDLE) && start_i) begin 
      target <= target_i;
    end
  end
end

// count 
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    count <= 'h0;
  end 
  else begin 
    case (state) 
      IDLE: begin 
        if (start_i) begin 
          count <= 'h0;
        end
      end
      ACTIVE: begin 
        if (en_i) begin 
          count <= count + 1'h1;
        end
      end
    endcase
  end
end

assign target_reached = (state == ACTIVE) && (target == count);
assign done_o = target_reached;

endmodule
