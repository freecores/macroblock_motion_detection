/////////////////////////////////////////////////////////////////////
////                                                             ////
////  FrametoMacroblockTest.v                                    ////
////                                                             ////
////  Test bench for FrametoMacroBlock.v                         ////
////                                                             ////
////  This file reads data from files and feeds data to          ////
////  FrametoMacroBlock.v  The test files were generated         ////
////  using an MPEG decode program.  The files are separated     ////
////  by component (YUV) and the U and V components are 1/4      ////
////  the size of the Y files.  U and V data is upsampled to     ////
////  simulate high end 4:2:2 camera output and sent to the      ////
////  frame management module one component (8-bits) at a time.  ////
////                                                             ////
////  Simulation time in Modelsim Xilinx Starter Edition on      ////
////  a Pentium 1.4 is about an 1 1/2 hours for 5 9x5            ////
////  macroblock frames.                                         ////
////                                                             ////
////  Note that outputs for the first frame are not valid        ////
////  since there is no previous frame in memory.  Valid         ////
////  processing begins after the full 0 row of the second       ////
////  frame has been loaded.  The motion vectors are             ////
////  offset in a 9x9 Macroblock area.  Macroblocks with best    ////
////  match at current location will generate motion vector      ////
////  (16,16) -- the upper left corner of the center block.      ////
////                                                             ////
////  Timing is meant to match up with CCIR601 27MHz clock.      ////
////  9x5 macroblock frame (1/29.33 of 704x480) takes up         ////
////  853uS.  With horizontal and vertical synch time,  size     ////
////  of NTSC is 858x525.                                        ////
////  853uS * 29.33 * 858/704 * 525/480 * 29.97 f/s  = 1.0001s   ////
////                                                             ////
////  The first valid output is (17,16)                          ////
////                                                             ////
////  Author: James Edgar                                        ////
////          JamesSEDgar@Hotmail.com                            ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2004 James Edgar                              ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// This disclaimer of warranty extends to the user of these    ////
//// programs and user's customers, employees, agents,           ////
//// transferees, successors, and assigns.                       ////
////                                                             ////
//// The author does not represent or warrant that the programs  ////
//// furnished hereunder are free of infringement of any         ////
//// third-party patents.                                        ////
////                                                             ////
//// Commercial implementations of MPEG like video encoders      ////
//// including shareware, are subject to royalty fees to patent  ////
//// holders.  Many of these patents are general enough such     ////
//// that they are unavoidable regardless of implementation      ////
//// design.                                                     ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

// Defines for file access for test frames
`define EOF 32'hFFFF_FFFF
`define NULL 0
`define MAX_LINE_LENGTH 1000

module FrametoMacroBlock_Test_v_tf();

// DATE:     00:27:37 09/04/2004 
// MODULE:   FrametoMacroBlock
// DESIGN:   FrametoMacroBlock
// FILENAME: FrametoMacroBlockTest.v
// PROJECT:  Macroblock_Motion_Detection
// VERSION:  

// parameters

parameter frame_width  = 144; //352;	   // currently must be multiple of 16 720
parameter frame_height = 80;  //196;	   // currently must be multiple of 16 480

    reg       clk2;    // half speed clock
    reg [8:0] count;   // this is just to keep track of when motion vectors are available
// Inputs
    reg clk;
    reg ena;
    reg rst;
    reg dstrb;
    reg dclr;
    reg [7:0] din1;

// Outputs
    wire [7:0] dout1;
    wire douten;
    wire [31:0] HP_dout;

// Bidirs


wire [16:0] address_0;
wire [31:0] data_0;
wire cs_0,we_0,oe_0;
wire [16:0] address_1;
wire [31:0] data_1;
wire cs_1,we_1,oe_1;


  // Instantiate the ram	 (Outside of FPGA, but all pins will connect to FPGA)
    ram_dp_sr_sw ram (
        .clk(clk), 
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

// Instantiate the UUT
    motion_detection_top #(frame_width, frame_height)
    motion_detection_top (
        .clk(clk), 
        .ena(ena), 
        .rst(rst), 
        .dstrb(dstrb), 
        .dclr(dclr), 
        .din1(din1), 
        .dout1(dout1), 
        .douten(douten),

	   .address_0(address_0), 
        .data_0(data_0), 
        .cs_0(cs_0), 
        .we_0(we_0), 
        .oe_0(oe_0), 
        .address_1(address_1), 
        .data_1(data_1), 
        .cs_1(cs_1), 
        .we_1(we_1), 
        .oe_1(oe_1),
	   .HP_dout(HP_dout)

        );

// Registers for file input

  integer file, fileu, filev;
  reg [3:0] bin;
  reg [31:0] dec, hex, uv;
  reg [9:0] countx, county;
  reg	uvflag,fill420flag;
  real real_time;
  reg [8*`MAX_LINE_LENGTH-1:0] line; /* Line of text read from file */
  integer c, r, i;
  reg [8*7:1] name;
  reg [8*7:1] nameu;
  reg [8*7:1] namev;
  reg [8*17:1] dir;
  reg [8*79:1] full;

// Initialize Inputs
 
initial begin
  clk = 0;
  ena = 0;
  rst = 0;
  dstrb = 0;
  dclr = 0;
  din1 = 0;
  countx = 0;
  county = 0;
  @(posedge clk);
  rst <= 1;
  ena <= 1;
  // Read Frames from YUV files 
  begin : file_block
    dir = ".\\SampleFrames\\";  //17
    name = "Vac10.Y";
    nameu = "Vac10.U";
    namev = "Vac10.V";
    while (name[23:17] < 50)	  //   50 = hex 32 -- process two frames
      begin
  	   $display("name[3]",name[24:17]);
	   full = {dir,name};
    	   file = $fopen(full,"r");
	   full = {dir,nameu};
    	   fileu = $fopen(full,"r");
	   full = {dir,namev};
    	   filev = $fopen(full,"r");
    	   if (file == `NULL)
 	     disable file_block;
	   countx = 0;
	   county = 0;
	   uvflag <= 0;
	   fill420flag = 0;
    	   c = $fgetc(file);
    	   while (c != `EOF)
	     begin
            /* Check the first character for comment */
   	       if (c == "/")
              r = $fgets(line, file);
   	       else
    	         begin   // Read Y
                // Push the character back to the file then read the next time
     		 r = $ungetc(c, file);
         		 hex = $fgetc(file);
    		    end // if c else
		  din1 <= hex;
		  @(posedge clk);		// two system clocks per input data
		  @(posedge clk);

		  // read U or V
		  if (uvflag == 0)
		    begin
		      uv = $fgetc(fileu);	
		    end
		  else
		    begin
		      uv = $fgetc(filev);
		    end
		  uvflag <= ~uvflag;
		  din1 <= uv;
		  if (countx == frame_width-1)
		    begin
		      countx <= 0;
		      county <= county+1;
		      if (county[0:0] == 1)
		        begin	// read u and v lines twice to simulate 4:2:2
		          for (i=0; i < (frame_width >> 1); i=i+1)
			       begin
				    r = $ungetc(c, fileu);
				    r = $ungetc(c, filev);
				  end
			   end
		    end
		  else
		    begin
		      countx <= countx+1;
		    end
		  @(posedge clk);
		  @(posedge clk);
		  c = $fgetc(file);
    		end // while not EOF
    			$fclose(file);
			$fclose(fileu);
			$fclose(filev);
			name[23:17] = name[23:17]+1;
			nameu[23:17] = nameu[23:17]+1;
			namev[23:17] = namev[23:17]+1;
			$display("full[3]",full[24:17]);
  		end


	 end	// frame loop
    $stop;
end
   // Display changes to input signals
   // always @(hex)
   // $display("This is one %h", hex, " U or V = %h " , uv);

   // Display Y Macroblock input #
   always @(county[4:4])
     $display("Y MacroBlock Input Row = %d ", county[9:4]);

   // Display the motion vectors
  always @(posedge clk2)
    begin
      if (ena)
      begin
	   if (count > 507)	   // motion vector output at 509 511
  	     begin
		  if (dout1) // eliminates 0 0 from initialization cycle
		    begin
		      case (count)
		        509: $display("X offset is  %d ", dout1);
			   511: $display("Y offset is  %d ", dout1);
			 endcase
		    end
		end
      end
    end

 	// generate clock  (54MHz)
	always #9.25926 clk <= ~clk;

  // control for clk2
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   clk2  <= 0;
	 end
    else
    if (ena)
      begin
	   clk2 <= ~clk2;
	 end
  end

always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   count  <= 0;
	 end
    else
    if (ena)
      begin
	   count <= count + 1;
	 end
  end

endmodule

