/*
* Uart Serializer.
*/
module UartSerializer
(
  input clk, 
  input rst, 
  input baud_clk_rising_edge,
  input baud_clk_falling_edge, 
  input fifo_empty_i, 
  input [7:0] fifo_rd_data_i,
  output fifo_rd_en_o,
  output logic tx_o
); 

  reg [2:0] bit_count;
  reg [7:0] shift_reg;
  reg shift_reg_rd_en;

  logic baud_clk_edge;

  /*
  * STATE MACHINE
  */

  logic start_transition; 
  logic start_to_transmit_transition; 
  logic transmit_to_stop_transition; 
  logic stop_to_idle_transition;

  typedef enum bit[1:0]
  {
    IDLE, 
    START, 
    TRANSMIT, 
    STOP
  } states_t;

  reg [1:0] state; 
  logic [1:0] next_state; 

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
        if (start_transition) begin 
          next_state = START;
        end 
      end
      START: begin
        next_state = START;
        if (start_to_transmit_transition) begin 
          next_state = TRANSMIT; 
        end
      end
      TRANSMIT: begin
        next_state = TRANSMIT;
        if (transmit_to_stop_transition) begin 
          next_state = STOP;
        end
      end
      STOP: begin
        next_state = STOP; 
        if (start_transition) begin 
          next_state = START;
        end
        else if (stop_to_idle_transition) begin 
          next_state = IDLE;
        end
      end
      default: begin
        next_state = IDLE;
      end
    endcase
  end

  assign start_transition = baud_clk_falling_edge & (~fifo_empty_i);
  assign start_to_transmit_transition = baud_clk_rising_edge;
  assign transmit_to_stop_transition = baud_clk_rising_edge & (bit_count == 'd7);
  assign stop_to_idle_transition = baud_clk_falling_edge;

  /*
  * SEQUENTIAL 
  */

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      bit_count <= 'd0;
    end
    else begin 
      case (state) 
        TRANSMIT: begin 
          if (baud_clk_edge) begin 
            bit_count <= bit_count + 1'd1;
          end
        end
        default: begin 
          bit_count <= 'd0;
        end
      endcase
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      shift_reg_rd_en <= 1'h0;
    end
    else begin 
      shift_reg_rd_en <= fifo_rd_en_o;
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      shift_reg <= 'h0;
    end
    else begin 
      case (state) 
        START: begin 
          if (shift_reg_rd_en) begin 
            shift_reg <= fifo_rd_data_i;
          end
        end
        TRANSMIT: begin
          if (baud_clk_edge) begin 
            shift_reg <= shift_reg >> 1;
          end
        end
        default begin 
        end
      endcase
    end
  end

  /*
  * COMBINATIONAL
  */

  always_comb begin 
    case (state) 
      START:  begin
        tx_o = 1'h0;       
      end
      TRANSMIT: begin 
        tx_o = shift_reg[0];
      end
      default: begin 
        tx_o = 1'h1;
      end
    endcase
  end

  assign baud_clk_edge = baud_clk_rising_edge | baud_clk_falling_edge;
  assign fifo_rd_en_o = start_transition;

endmodule
