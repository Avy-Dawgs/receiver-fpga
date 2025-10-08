/*
* Interface for Adc. 
* Handles clock domain crossing to system clock.
*/
module AdcInterface (
  input io_clk,   // fast clock running at multiple of 87.5 MHz
  input sys_clk,  // slower system clock (125 MHz)
  input rst,
  input sck, 
  input mosi,
  output cs_n,
  output [11:0] data_o, 
  output valid_o
  ); 

// timing description: (based on 175 MHz IO clk)
// cs goes low, wait one clock cycle to bring sck low 
// on 14th rising edge of sck, bring cs high

localparam SPI_DW = 14;
localparam DW = 12;

localparam SCK_FREQ = 87.5e6; 
localparam IO_CLK_FREQ = 175e6;

wire sck_rising_edge;
wire sck_falling_edge;
wire sck_sample_edge;

wire [SPI_DW - 1:0] spi_data;

reg [4:0] falling_edge_count;

// edge count 0: wait 
// edge count 3 to 25: sample on rising edge 
// edge count 26 to <>: wait

// reg [$clog2(SPI_DW - 1:0)]

assign sck_sample_edge = sck_rising_edge;

always_ff @(posedge io_clk, posedge rst) begin 
  if (rst) begin 
    falling_edge_count <= 'h0;
  end
  else begin 
    if (falling_edge_count == 'h18) begin 
      falling_edge_count <= 'h0;
    end
    else if (sck_falling_edge) begin 
      falling_edge_count <= falling_edge_count + 1'h1;
    end

  end

end

// TODO: 
// generate cs_n
// generate sck

ClockGenerator #(
  .CLK_FREQ(IO_CLK_FREQ), 
  .TARGET_CLK_FREQ(SCK_FREQ)
  )
  sck_generator (
    .clk(io_clk), 
    .rst(rst), 
    .gen_clk_o(sck)
  );

EdgeDetector_synchronous 
  sck_edge_detector (
    .clk(io_clk),
    .rst(rst),
    .test_clk(sck),
    .rising_edge(sck_rising_edge),
    .falling_edge(sck_falling_edge)
  );

SpiDeserializer #(
  .DW(SPI_DW)
  ) 
  spi_deserializer (
    .clk(io_clk),
    .rst(rst),
    .sck_sample_edge(sck_rising_edge),
    .mosi(mosi),
    .cs_n_falling_edge(),
    .data_o(spi_data)
  );

Fast2SlowCdc #(
  .DW(DW)
  )
  cdc (
    .fst_clk(io_clk), 
    .slw_clk(sys_clk), 
    .rst(rst), 
    .data_i(), 
    .valid_i(), 
    .data_o(data_o), 
    .valid_o(valid_o)
  );

endmodule
