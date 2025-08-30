/*
* LUT for flattop window.
*/
module FlatTopWindowLut 
#(
  SIZE_POW2, 
  FRAC_BITS
)
(
  input clk, 
  input rst, 
  input [SIZE_POW2 - 1:0] n_i, 
  output reg [FRAC_BITS - 1:0] w_o
); 

  localparam SIZE = 2**SIZE_POW2;
  localparam HALFSIZE = 2**(SIZE_POW2/2);

  localparam real PI = 3.14159265359;

  localparam real A0 = 0.21557895, 
                  A1 = 0.41663158, 
                  A2 = 0.277263158, 
                  A3 = 0.083578947, 
                  A4 = 0.006947368; 

  function automatic real calc_coeff_real; 
    input int n; 
    input int L;

    begin 
      return 
        + A0 
        - A1 * $cos(2*PI*n/(L - 1))
        + A2 * $cos(4*PI*n/(L - 1))
        - A3 * $cos(6*PI*n/(L - 1)) 
        + A4 * $cos(8*PI*n/(L - 1));
    end
  endfunction

  // half sized lut because window is symmetrical
  reg [FRAC_BITS:0] half_lut [0:2**(SIZE_POW2/2)  - 1];
  logic [SIZE_POW2 - 2:0] half_lut_addr;

  initial begin 
    for (int i = 0; i < 2**(SIZE_POW2/2); i++) begin 
      half_lut[i] = $rtoi(calc_coeff_real(.n(i), .L(2**SIZE)) * 2**FRAC_BITS);
    end
  end

  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      w_o <= 'h0;
    end
    else begin 
      w_o <= half_lut[half_lut_addr];
    end
  end

  always_comb begin 
    // MSB of n indicates which half
    
    // second half
    if (n_i[SIZE_POW2 - 1]) begin 
      half_lut_addr = n_i[SIZE_POW2 - 2:0];
    end
    // first half
    else begin 
      half_lut_addr = (HALFSIZE - 1) - n_i[SIZE_POW2 - 2:0];
    end
  end

endmodule
