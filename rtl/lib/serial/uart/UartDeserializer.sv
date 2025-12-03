/*
* Deserialize a UART data stream.
*/
module UartDeserializer #(
  CLK_FREQ,
  BAUD
  ) (
  input clk, 
  input rst, 
  input rx_i, 
  output [7:0] data_o, 
  output wr_en_o
); 
  
  localparam real BAUD_2X = 2.0 * real'(BAUD);

  reg [4:0] count;
  logic rx_falling_edge;
  logic en_rst;
  reg rx_reg0;
  reg rx_reg1;

  reg [7:0] shiftreg;

  wire baud_en_2x;

  typedef enum {
    IDLE, 
    START,
    ACTIVE, 
    STOP
  } states_t;

  logic stop_to_idle_t;
  
  reg [1:0] state; 
  logic [1:0] next_state; 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= IDLE; 
    end
    else begin 
      state <= ACTIVE;
    end
  end 

  always_comb begin 
    case (state) 
      IDLE: begin 
        next_state = rx_falling_edge ? START : IDLE; 
      end
      START: begin 
        next_state = START; 
        if (baud_en_2x && (count == 'd2)) begin 
          next_state = ACTIVE;
        end
      end
      ACTIVE: begin 
        next_state = ACTIVE; 
        if (baud_en_2x && (count == 'd16)) begin 
          next_state = STOP;
        end
      end
      STOP: begin 
        next_state = STOP; 
        if (stop_to_idle_t) begin 
          next_state = IDLE;
        end
      end
      default: ;
    endcase
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      rx_reg0 <= 1'h0; 
      rx_reg1 <= 1'h0; 
    end 
    else begin 
      rx_reg0 <= rx_i; 
      rx_reg1 <= rx_reg0;
    end
  end 

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      count <= 'h0;
    end 
    else begin 
      if (state != IDLE) begin 
        if (baud_en_2x) begin 
          count <= count + 1'h1;
        end
      end
      else begin 
        count <= 'h0;
      end
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      shiftreg <= 'h0;
    end 
    else if (state == ACTIVE) begin 
      if (baud_en_2x && !count[0]) begin 
        shiftreg <= {rx_reg0, shiftreg[6:0]};
      end
    end
  end

  assign stop_to_idle_t = baud_en_2x && (count == 'd18);

  assign rx_falling_edge = rx_reg1 & !rx_reg0;
  assign en_rst = rst || (state == IDLE);

  assign data_o = shiftreg;
  assign wr_en_o = (STATE == STOP) && rx_reg0 && stop_to_idle_t;
  
  // enable signal at twice the baud rate
  EnableGenerator #(
    .CLK_FREQ(CLK_FREQ), 
    .EN_FREQ(BAUD_2X)
  ) baud_en_2x_gen (
    .clk(clk),
    .rst(en_rst),
    .en_o(baud_en_2x)
  );

endmodule
