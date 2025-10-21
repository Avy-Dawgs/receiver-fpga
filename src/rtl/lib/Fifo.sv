/*
* FIFO.
*/
module Fifo
#(
  DW = 8, 
  SIZE_POW2=2
  )
(
  input clk, 
  input rst, 
  input wr_en_i, 
  input rd_en_i, 
  input [DW - 1:0] wr_data_i, 
  output reg [DW - 1:0] rd_data_o, 
  output full_o, 
  output empty_o
  ); 

  reg [DW - 1:0] memory [0:2**SIZE_POW2 - 1];
  reg [SIZE_POW2 - 1:0] rd_idx, wr_idx;

  logic do_rd, do_wr;

  // read
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      rd_data_o <= 'h0;
    end
    else begin 
      if (do_rd) begin 
        rd_data_o <= memory[rd_idx];
      end
    end
  end

  // write
  // write must not be in an asyncronous reset block because it 
  // is not supported by xilinx block ram
  always_ff @(posedge clk) begin 
    if (do_wr) begin 
      memory[wr_idx] <= wr_data_i;
    end
  end

  // pointers
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      wr_idx <= 'h0;
      rd_idx <= 'h0;
    end
    else begin 
      if (do_wr) begin 
        wr_idx <= wr_idx + 1'd1;
      end
      if (do_rd) begin 
        rd_idx <= rd_idx + 1'd1;
      end
    end
  end

  assign empty_o = (rd_idx == wr_idx); 
  assign full_o = (rd_idx == (wr_idx + 1'd1));
  assign do_rd = rd_en_i & (~empty_o);
  assign do_wr = wr_en_i & (~full_o);

endmodule
