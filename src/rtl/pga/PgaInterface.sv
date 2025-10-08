/*
* Interface for controlling PGA. 
* 
* Set gain by using set_i. done_o signal goes high when SPI transfer is
* complete.
*/
module PgaInterface #(
  CLK_FREQ
  ) (
  input clk, 
  input rst, 
  input [7:0] gain_i, 
  input set_i,
  output done_o, 

  output logic sck, 
  output logic cs_n, 
  output logic miso
); 

localparam DW = 8;

localparam SCK_FREQ = 12.5e6;

wire sck_internal; 
wire sck_falling_edge; 
wire sck_rising_edge;
logic sck_shift_edge;

logic cs_n;
logic cs_n_falling_edge;

wire serializer_miso;

reg [$clog2(DW-1) - 1:0] bit_count;

typedef enum bit[1:0]{
  IDLE, 
  WAIT_FOR_EDGE,
  TRANSFER
} states_t;

reg [1:0] state; 
logic [1:0] next_state; 

// state transition
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    state <= IDLE;
  end 
  else begin 
    state <= next_state;
  end
end

// state transiiton
always_comb begin 
  case (state)
    IDLE: begin
      next_state = set_i ? WAIT_FOR_EDGE : IDLE;
    end
    WAIT_FOR_EDGE: begin 
      next_state = sck_shift_edge ? TRANSFER : WAIT_FOR_EDGE;
    end
    TRANSFER: begin 
      next_state = TRANSFER;
      if (sck_shift_edge && (bit_count == (DW-1))) begin 
        next_state = IDLE;
      end
    end
    default: begin 
      next_state = IDLE;     
    end
  endcase
end

// bit counter 
always_ff @(posedge clk, posedge rst) begin 
  if (rst) begin 
    bit_count <= 'h0;
  end
  else begin 
    if (state == TRANSFER) begin 
      if (sck_shift_edge) begin 
        bit_count <= bit_count + 1'h1;
      end
    end
    else begin 
      bit_count <= 'h0;
    end
  end
end

// output logic
always_comb begin 
    if (state == TRANSFER) begin 
      cs_n = 1'h0;
      miso = serializer_miso;
      sck = sck_internal;
    end
    else begin 
      cs_n = 1'h1;
      miso = 1'h1;
      sck = 1'h0;
    end
end

assign cs_n_falling_edge = (state == WAIT_FOR_EDGE) && sck_shift_edge;
assign done_o = (state == TRANSFER) && sck_shift_edge;
assign sck_shift_edge = sck_falling_edge;

SpiSerializer #(
  .DW(DW)
  ) 
  serializer ( 
    .clk(clk), 
    .rst(rst), 
    .data_i(gain_i), 
    .sck_shift_edge(sck_shift_edge), 
    .cs_n_falling_edge(cs_n_falling_edge), 
    .miso(serializer_miso)
  );


ClockGenerator #(
  .CLK_FREQ(CLK_FREQ), 
  .TARGET_CLK_FREQ(SCK_FREQ)
  ) 
  sck_clock_generator (
    .clk(clk), 
    .rst(rst), 
    .gen_clk_o(sck_internal),
  );

EdgeDetector_synchronous 
  sck_edge_detector (
    .clk(clk), 
    .rst(rst), 
    .test_clk(sck_internal), 
    .rising_edge(sck_rising_edge), 
    .falling_edge(sck_falling_edge)
  );

endmodule
