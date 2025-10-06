module Fast2SlowCdc #(
  DW
)
(
  input fst_clk, 
  input slw_clk, 
  input rst,
  input [DW - 1:0] data_i, 
  input valid_i, 
  output [DW - 1:0] data_o,
  output valid_o
  ); 

  /*
  * Fast clock domain: 
    * register input on valid 
    * hold input in registers until acknowledge is received
  * 
  * Slow clock domain: 
    * output is valid on rising edge of valid input signal
  */

  reg new_data_fst;
  reg [DW - 1:0] data_fst;

  reg valid1_slw, valid2_slw, valid3_slw;
  reg [DW - 1:0] data1_slw, data2_slw, data3_slw;
  reg ack1_fst, ack2_fst;

  /*********************** 
  * FAST CLOCK DOMAIN 
  * *********************/

  /*
  * This state machine waits for acknowledge before 
  * listening for new data again
  */

  typedef enum {
    WAIT_FOR_VALID, 
    WAIT_FOR_ACK
  } fst_states_t;

  reg state; 
  logic next_state; 

  // state transition
  always_ff @(posedge fst_clk, posedge rst) begin 
    if (rst) begin
      state <= WAIT_FOR_VALID;
    end
    else begin 
      state <= next_state;
    end
  end

  // next state
  always_comb begin 
    case (state) 
      WAIT_FOR_VALID: begin 
        next_state = valid_i ? WAIT_FOR_ACK : WAIT_FOR_VALID;
      end
      WAIT_FOR_ACK: begin 
        next_state = ack2_fst ? WAIT_FOR_VALID : WAIT_FOR_ACK;
      end
      default: begin
        next_state = WAIT_FOR_VALID;
      end
    endcase
  end

  // fast clock new data and data registers
  always_ff @(posedge fst_clk, posedge rst) begin 
    if (rst) begin 
      new_data_fst <= 1'h0;
      data_fst <= 'h0;
    end
    else begin 
      // register new data only when waiting for valid
      // (if waiting for ack, registers should remain same)
      if (state == WAIT_FOR_VALID) begin 
        // new data: register inputs
        if (valid_i) begin 
          new_data_fst <= 1'h1;
          data_fst <= data_i;
        end
        // if no new data, make sure new data indicator low
        else begin 
          new_data_fst <= 1'h0;
        end
      end
    end
  end

  // ack signal from slow clock domain
  always_ff @(posedge fst_clk, posedge rst) begin 
    if (rst) begin 
      ack1_fst <= 1'h0; 
      ack2_fst <= 1'h0;
    end
    else begin 
      ack1_fst <= valid2_slw; 
      ack2_fst <= ack1_fst;
    end
  end


  /********************** 
  * SLOW CLOCK DOMAIN 
  * ********************/

  // double registers
  always_ff @(posedge slw_clk, posedge rst) begin 
    if (rst) begin 
      valid1_slw <= 1'h0; 
      valid2_slw <= 1'h0;
      valid3_slw <= 1'h0;
      data1_slw <= 'h0;
      data2_slw <= 'h0;
    end 
    else begin 
      valid1_slw <= new_data_fst; 
      valid2_slw <= valid1_slw;
      valid3_slw <= valid2_slw;
      data1_slw <= data_fst; 
      data2_slw <= data1_slw;
    end
  end

  // valid on rising edge of valid signal
  assign valid_o = (~valid3_slw) && valid2_slw;
  assign data_o = data2_slw;

endmodule
