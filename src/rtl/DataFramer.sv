/*
* Frames data to be sent out via UART.
*/
module DataFramer (
  input clk, 
  input rst, 
  input [15:0] data_i,
  input valid_i, 
  output logic [7:0] uart_data,
  output logic wr_en_o
  ); 

  localparam START_BYTE = 8'hAA; 
  localparam END_BYTE = 8'hBB;

  reg [15:0] datareg;

  typedef enum {
    IDLE, 
    WR_START, 
    WR_B0, 
    WR_B1, 
    WR_END
  } states_t;

  reg [2:0] state; 
  logic [2:0] next_state;

  // state transistion
  always @(posedge clk, posedge rst) begin 
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
        next_state = WR_B0;
      end
      WR_B0: begin 
        next_state = WR_B1;
      end
      WR_B1: begin 
        next_state = WR_END;
      end
      WR_END: begin 
        next_state = IDLE;
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
      if ((state == IDLE) && valid_i) begin
        datareg <= data_i;
      end
    end
  end

  // outputs
  always_comb begin 
    wr_en_o = 1'h0;
    uart_data = 'h0;
    case (state) 
      WR_START: begin 
        uart_data = START_BYTE;
        wr_en_o = 1'h1;
      end
      WR_B0: begin 
        uart_data = datareg[7:0];
        wr_en_o = 1'h1;
      end 
      WR_B1: begin 
        uart_data = datareg[15:8];
        wr_en_o = 1'h1;
      end
      WR_END: begin 
        uart_data = END_BYTE;
        wr_en_o = 1'h1;
      end
      default: begin 
        uart_data = 'h0;
        wr_en_o = 1'h0;
      end
    endcase
  end

endmodule
