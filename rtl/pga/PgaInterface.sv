/*
* Interface for controlling PGA. 
* 
* Set gain by using set_i. ready_o signal indicates that the interface 
* is ready to set again.
* complete.
*/
module PgaInterface (
  input sck,
  input rst, 
  input [7:0] code_i, 
  input set_i, 
  output logic ready_o,
  output reg cs_n, 
  output logic mosi
); 

  reg [7:0] shiftreg; 
  reg [2:0] bit_count;

  logic last_bit;

  typedef enum {
    IDLE,   // waiting for set_i
    ACTIVE, // transfer bits
    WAIT    // to prevent setting again too soon
  } states_t;

  reg [1:0] state; 
  logic [1:0] next_state; 

  // state transition
  always_ff @(negedge sck, posedge rst) begin 
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
        next_state = set_i ? ACTIVE : IDLE;
      end 
      ACTIVE: begin 
        next_state = ACTIVE; 
        if (last_bit) begin 
          next_state = WAIT;
        end
      end
      WAIT: begin 
        next_state = IDLE; 
      end
      default: begin 
        next_state = IDLE;
      end
    endcase
  end

  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end 
    else begin 
      if ((state == IDLE) && set_i) begin
        shiftreg <= code_i;
      end
      else if (state == ACTIVE) begin
        shiftreg <= {shiftreg[6:0], 1'h0};
      end
    end 
  end

  // bit count
  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      bit_count <= 'h0;
    end
    else begin 
      if (state == ACTIVE) begin 
        bit_count <= bit_count + 1'h1;
      end
      else begin 
        bit_count <= 'h0;
      end
    end
  end

  always_ff @(negedge sck, posedge rst) begin 
    if (rst) begin 
      cs_n <= 1'h1;
    end
    else begin 
      if (last_bit) begin 
        cs_n <= 1'h1;
      end
      else if ((state == IDLE) && set_i) begin 
        cs_n <= 1'h0;
      end
    end
  end

  assign mosi = shiftreg[7];
  assign ready_o = !rst && (state == IDLE);
  assign last_bit = (bit_count == 'd7);

endmodule
