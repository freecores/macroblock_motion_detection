
//synopsys translate_off
`include "timescale.v"
//synopsys translate_on
module motion_detection_top(clk, ena, rst, dstrb, dclr, din1,dout1,douten,
    					address_0, data_0, cs_0, we_0, oe_0, 
					address_1, data_1, cs_1, we_1, oe_1,
					HP_dout);
parameter frame_width  = 144; //352;	   // currently must be multiple of 16 720
parameter frame_height = 80;  //196;	   // currently must be multiple of 16 480

// Inputs
    input clk;
    input ena;
    input rst;
    input dstrb;
    input dclr;
    input [7:0] din1;

// Outputs
    output [7:0] dout1;
    output douten;
    output [31:0] HP_dout;


  output [16:0] address_0;
  output        cs_0;
  output        we_0;
  output        oe_0;
  output [16:0] address_1;
  output        cs_1;
  output        we_1;
  output        oe_1;

  inout [31:0] data_0;
  inout [31:0] data_1;


// Motion Detect wires
    wire MD_ena_top;
    wire MD_rst_top;
    wire [31:0] MD_din1_top, MD_din2_top;
    wire [3:0] MD_state_top;
    wire [8:0] MD_count_top;
    wire [31:0] MD_dout_top;

// HP Detect wires

    wire HP_ena;
    wire HP_rst;
    wire [31:0] HP_din1;
    wire [31:0] HP_din2;
    wire [3:0] HP_state;
    wire [8:0] HP_count;
    wire [5:0] HP_xoffset,HP_yoffset; // minx, miny from full pixel unit
    wire [31:0] HP_dout;

// Instantiate FrametoMacroBlock
    FrametoMacroBlock #(frame_width, frame_height)
    FrametoMacroBlock1 (
        .clk(clk), 
        .ena(ena), 
        .rst(rst), 
        .dstrb(dstrb), 
        .dclr(dclr), 
        .din1(din1), 
        .dout1(dout1), 
        .douten(douten),

	   .MD_ena(MD_ena_top), 
        .MD_rst(MD_rst_top), 
        .MD_din1(MD_din1_top),
        .MD_din2(MD_din2_top),	    
        .MD_dout(MD_dout_top), 
        .MD_state(MD_state_top),
	   .MD_count(MD_count_top),

	   .HP_ena(HP_ena),
	   .HP_rst(HP_rst),
	   .HP_din1(HP_din1),
        .HP_din2(HP_din2),
        .HP_state(HP_state),
        .HP_count(HP_count),
        .HP_xoffset(HP_xoffset),
	   .HP_yoffset(HP_yoffset),  // minx, miny from full pixel unit
        .HP_dout(HP_dout),

	   .address_0(address_0), 
        .data_0(data_0), 
        .cs_0(cs_0), 
        .we_0(we_0), 
        .oe_0(oe_0), 
        .address_1(address_1), 
        .data_1(data_1), 
        .cs_1(cs_1), 
        .we_1(we_1), 
        .oe_1(oe_1)

        );

  // Instantiate Motion Detection Module

      MotionDetection MotionDetection1 (
        .clk(clk), 
        .ena(MD_ena_top), 
        .rst(MD_rst_top), 
        .din1(MD_din1_top),
	   .din2(MD_din2_top), 
        .dout(MD_dout_top), 
        .state(MD_state_top),
	   .count(MD_count_top)
        );


// Instantiate the Half PEL Detection Module
    HalfPel HalfPel1 (
        .clk(clk), 
        .ena(HP_ena), 
        .rst(HP_rst), 
        .din1(HP_din1), 
        .din2(HP_din2), 
        .dout(HP_dout), 
        .state(HP_state), 
        .count(HP_count),
	   .xoffset(HP_xoffset),
	   .yoffset(HP_yoffset)
        );


endmodule
