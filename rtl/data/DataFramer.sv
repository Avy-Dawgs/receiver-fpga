/*
* Frames data to be sent out via UART.
*/
module DataFramer #(
  NBYTES
) (
  input clk, 
  input rst, 
  input [8*NBYTES - 1:0] data_i,
  input valid_i, 
  input uart_fifo_full_i,
  output logic [7:0] uart_data,
  output logic uart_wr_en_o
); 

  localparam START_BYTE = 8'hAA; 
  localparam END_BYTE = 8'hBB;

  localparam MAX_BYTE_COUNT = NBYTES - 1;

  reg [8*NBYTES - 1:0] datareg;

  reg [$clog2(MAX_BYTE_COUNT) - 1:0] byte_count;

  typedef enum {
    IDLE, 
    WR_START, 
    WR_BYTES, 
    WR_END
  } states_t;

  reg [1:0] state; 
  logic [1:0] next_state;

  // state transistion
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
        next_state = valid_i ? WR_START : IDLE;
      end
      WR_START: begin 
        next_state = uart_fifo_full_i ? WR_START : WR_BYTES;
      end
      WR_BYTES: begin 
        next_state = WR_BYTES; 
        if ((byte_count == MAX_BYTE_COUNT) && !uart_fifo_full_i) begin 
          next_state = WR_END;
        end
      end
      WR_END: begin 
        next_state = uart_fifo_full_i ? WR_END : IDLE;
      end
      default: begin 
        next_state = IDLE;
      end
    endcase
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      datareg <= 'h0;
    end 
    else begin 
      if (state == IDLE) begin 
        if (valid_i) begin
          datareg <= data_i;
        end
      end 
      else if (state == WR_BYTES) begin 
        if (!uart_fifo_full_i) begin 
          datareg <= datareg >> 8;
        end
      end
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin
      byte_count <= 'h0;
    end 
    else begin
      if (state == WR_BYTES) begin 
        byte_count <= byte_count + 1'h1;
      end
      else begin 
        byte_count <= 'h0;
      end
    end
  end

  always_comb begin 
    case (state) 
      WR_START: begin 
        uart_data = START_BYTE;
      end 
      WR_END: begin 
        uart_data = END_BYTE; 
      end 
      default: begin 
        uart_data = datareg[7:0];
      end
    endcase
  end

  assign uart_wr_en_o = (state != IDLE) && !uart_fifo_full_i;

endmodule
