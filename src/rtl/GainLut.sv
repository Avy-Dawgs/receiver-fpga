/*
* Determine digital pot code and hga bypass from gain.
*/
module GainLut (
  input signed [7:0] gain_dB_i,
  output logic [7:0] pga_code_o, 
  output logic hga_bypass_o
  ); 

  localparam signed [5:0] MIN_LUT_ADDR = -4;
  localparam signed [5:0] MAX_LUT_ADDR = 19; 

  typedef enum {
    GAIN_M16DB = -4,
    GAIN_M12DB = -3,
    GAIN_M8DB = -2,
    GAIN_M4DB = -1,
    GAIN_0DB = 0, 
    GAIN_4DB = 1, 
    GAIN_8DB = 2, 
    GAIN_12DB = 3, 
    GAIN_16DB = 4, 
    GAIN_20DB = 5, 
    GAIN_24DB = 6, 
    GAIN_28DB = 7, 
    GAIN_32DB = 8, 
    GAIN_36DB = 9, 
    GAIN_40DB = 10, 
    GAIN_44DB = 11, 
    GAIN_48DB = 12, 
    GAIN_52DB = 13, 
    GAIN_56DB = 14, 
    GAIN_60DB = 15, 
    GAIN_64DB = 16, 
    GAIN_68DB = 17, 
    GAIN_72DB = 18, 
    GAIN_76DB = 19
  } gain_t;

  logic signed [5:0] gain_dB_div4;    // input divided by 4
  logic signed [5:0] lut_addr;        // address used for LUT

  // input clamping
  always_comb begin 
    if (gain_dB_div4 > MAX_LUT_ADDR) begin 
      lut_addr = MAX_LUT_ADDR; 
    end
    else if (gain_dB_div4 < MIN_LUT_ADDR) begin 
      lut_addr = MIN_LUT_ADDR;
    end
    else begin 
      lut_addr = gain_dB_div4;
    end
  end

  // LUT
  always_comb begin 
    case (lut_addr) 
      GAIN_M16DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h4F;
      end
      GAIN_M12DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h5B;
      end
      GAIN_M8DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h67;
      end
      GAIN_M4DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h73;
      end
      GAIN_0DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h80;
      end
      GAIN_4DB: begin 
        hga_bypass_o = 1'h1;
        pga_code_o = 8'h8D;
      end
      GAIN_8DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'h99;
      end
      GAIN_12DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hA5;
      end
      GAIN_16DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hB1;
      end
      GAIN_20DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hBB;
      end
      GAIN_24DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hC5;
      end
      GAIN_28DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hCD;
      end
      GAIN_32DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hD5;
      end
      GAIN_36DB: begin 
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'hDC;
      end
      GAIN_40DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'h80;
      end
      GAIN_44DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'h8D;
      end
      GAIN_48DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'h99;
      end
      GAIN_52DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hA5;
      end
      GAIN_56DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hB1;
      end
      GAIN_60DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hBB;
      end
      GAIN_64DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hC5;
      end
      GAIN_68DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hCD;
      end
      GAIN_72DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hD5;
      end
      GAIN_76DB: begin 
        hga_bypass_o = 1'h0; 
        pga_code_o = 8'hDC;
      end
      default: begin 
        // unity gain on PGA and bypassed HGA are safe choices
        hga_bypass_o = 1'h1; 
        pga_code_o = 8'h80; 
      end
    endcase
  end

  assign gain_dB_div4 = gain_dB_i >>> 2;

endmodule
