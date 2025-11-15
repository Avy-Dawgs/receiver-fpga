/*
* Top level for controlling the analog front end.
*/
module AfeControl (
  input clk, 
  input rst, 
  input signed [7:0] gain_dB_i,       // gain in dB
  input set_gain_i,
  output logic [7:0] pga_code_o,
  output logic set_pga_o,
  input set_pga_done_i,
  output logic hga_bypass_o,
  output logic set_in_progress_o
); 

  localparam PGA_RSTVAL = 8'h80;
  localparam HGA_RSTVAL = 1'h1;

  // register that holds the current gain (befure LUT)
  reg signed [5:0] gain_dB_reg;     // gain in dB / 4
  logic gain_dB_reg_we;

  // from the LUT
  wire [7:0] lut_pga_code; 
  wire lut_hga_bypass;

  // registers to hold the current configuration for the AFE (after LUT)
  reg [7:0] pga_code_reg;
  reg hga_bypass_reg;
  logic pga_code_reg_we;
  logic hga_bypass_reg_we;

  // state machine to control setting of gain

  /*************** 
  * STATE MACHINE 
  * **************/

  typedef enum {
    INIT,                   // reset state
    IDLE,               // wait for gain set signal
    GAIN_EVAL__LOOKUP,            // get new values for PGA and HGA from LUT
    GAIN_EVAL__WRITE_SEQ_DETERMINE,    // determine which write sequence to use to set gain
    // ---- write sequenes ------
    // only PGA has to be changed
    PGA_ONLY__SET,           
    PGA_ONLY__WAIT,
    // only HGA has to be changed
    HGA_ONLY__SET,         
    // both have to be changed, HGA is going from active to bypassed (decrease
    // in gain)
    BOTH_DEC__SET, 
    BOTH_DEC__WAIT,
    // both have to be changed, HGA is going from bypassed to active (increase
    // in gain)
    BOTH_INC__PGA_SET, 
    BOTH_INC__PGA_WAIT, 
    BOTH_INC__HGA_SET
  } states_t; 

  reg [3:0] state; 
  logic [3:0] next_state; 

  // state transition 
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      state <= INIT;
    end 
    else begin 
      state <= next_state;
    end 
  end

  // next state 
  always_comb begin 
    case (state) 
      INIT: begin 
        // choose this state to quickly set gain
        next_state = BOTH_DEC__SET;
      end
      IDLE: begin 
        next_state = IDLE; 
        if (set_gain_i) begin 
          next_state = GAIN_EVAL__LOOKUP;
        end
      end
      GAIN_EVAL__LOOKUP: begin 
        next_state = GAIN_EVAL__WRITE_SEQ_DETERMINE;
      end
      GAIN_EVAL__WRITE_SEQ_DETERMINE: begin 
        // HGA bypasses are the same, only PGA is set
        if (hga_bypass_reg == lut_hga_bypass) begin 
          next_state = PGA_ONLY__SET;
        end
        // PGA gains are the same, only HGA is set
        else if (lut_pga_code == pga_code_reg) begin 
          next_state = HGA_ONLY__SET;
        end
        // HGA goes from bypasssed to active
        else if (!hga_bypass_reg && lut_hga_bypass) begin 
          next_state = BOTH_INC__PGA_SET;
        end
        // HGA goes from active to bypassed
        else begin 
          next_state = BOTH_DEC__SET;
        end
      end
      // ----- PGA only ----- 
      PGA_ONLY__SET: begin 
        next_state = PGA_ONLY__WAIT;
      end
      PGA_ONLY__WAIT: begin 
        next_state = PGA_ONLY__WAIT;
        // if PGA is done being set
        if (set_pga_done_i) begin 
          next_state = WINDOW__START;
        end
      end
      // ----- HGA only -----
      HGA_ONLY__SET: begin 
        // simple GPIO set, don't need to wait for anything
        next_state = WINDOW__START;
      end
      // ----- both dec -----
      BOTH_DEC__SET: begin 
        next_state = BOTH_DEC__WAIT;
      end
      BOTH_DEC__WAIT: begin 
        next_state = BOTH_DEC__WAIT;
        // if PGA is done being set
        if (set_pga_done_i) begin
          next_state = WINDOW__START;
        end
      end
      // ----- both inc -----
      BOTH_INC__PGA_SET: begin 
        next_state = BOTH_INC__PGA_WAIT;
      end
      BOTH_INC__PGA_WAIT: begin 
        next_state = BOTH_INC__PGA_WAIT;
        // if PGA is done being set
        if (set_pga_done_i) begin 
          next_state = BOTH_INC__HGA_SET;
        end
      end
      BOTH_INC__HGA_SET: begin
        next_state = WINDOW__START;
      end
      default: begin 
        next_state = INIT;
      end
    endcase
  end

  // control signals determind by state
  always_comb begin 
    hga_bypass_reg_we = 1'h0; 
    pga_code_reg_we = 1'h0; 
    set_pga_o = 1'h0;
    set_in_progress_o = 1'h1;

  end

  /****************** 
  * SEQUENTIAL 
  * ****************/

  // gain register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      gain_dB_reg <= 'h0;
    end 
    else if (gain_dB_reg_we) begin 
      gain_dB_reg <= gain_dB_i >>> 2;
    end
  end

  // pga code register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      pga_code_reg <= PGA_RSTVAL;
    end 
    else if (pga_code_reg_we) begin 
      pga_code_reg <= lut_pga_code;
    end
  end

  // hga bypass register
  always_ff @(posedge clk, posedge rst) begin 
    if (rst) begin 
      hga_bypass_reg <= HGA_RSTVAL;
    end 
    else if (hga_bypass_reg_we) begin 
      hga_bypass_reg <= lut_hga_bypass;
    end
  end

  /****************** 
  * Combinational 
  * ****************/

  assign hga_bypass_o = hga_bypass_reg;
  assign pga_code_o = pga_code_reg;

  /******************** 
  * MODULES
  * ******************/

  GainLut (
    .gain_dB_i(gain_dB_reg), 
    .pga_code_o(lut_pga_code), 
    .hga_bypass_o(lut_hga_bypass)
    );

endmodule
