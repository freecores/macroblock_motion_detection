/////////////////////////////////////////////////////////////////////
////                                                             ////
////  FrametoMacroBlock.v                                        ////
////                                                             ////
////  Buffers data from frames to Motion.v for motion            ////
////  estimation.  Data is assumed to arrive in 4:2:2            ////
////  format in YUYV order.  Data is separated by component      ////
////  (presumably in off chip ram.)  U and V data is down        ////
////  sampled to 4:2:0 by discarding every other row for         ////
////  use in MPEG like system.  Currently, U and V data          ////
////  are ignored since program outputs motion vectors           ////
////  for macroblocks, but does not yet do half pel motion       ////
////  estimation or output differences between macroblock        ////
////  and best match for furthur processing.                     ////
////                                                             ////
////  Memory access is assumed to run at 54MHz, but most         ////
////  other processing occurs based on clk2 which runs at        ////
////  half speed (including 8 bit inputs of YUV data)            ////
////  to match digital NTSC/PAL like data rates.                 ////
////                                                             ////
////                                                             ////
////                                                             ////
////                                                             ////
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
module FrametoMacroBlock(clk, ena, rst, dstrb, dclr, din1,dout1,douten,
    					MD_ena, MD_rst, MD_din1, MD_din2, MD_state, MD_dout, MD_count,
					HP_ena, HP_rst, HP_din1, HP_din2, HP_state, HP_dout, HP_count,
        				HP_xoffset, HP_yoffset,
					address_0, data_0, cs_0, we_0, oe_0, address_1, data_1, cs_1, we_1, oe_1);
  reg clk2;  //1/2 speed clk for data input
  reg [8:0] count;			// 512 cycle counter to synch with Motion block inputs
  // parameters
  parameter frame_width = 352; //720;
  parameter frame_height = 200; //480;
  parameter xmblocks = frame_width >> 4;
  parameter ymblocks = frame_height >> 4;
  parameter uoffset = frame_width*frame_height - (frame_width >> 4);
  parameter voffset = frame_width*frame_height;
  parameter frameoffset = frame_width*frame_height+((frame_width*frame_height)>>1);
  parameter yblkoffset = frame_width * 4;  // number of mem locs for 1 line of macroblocks
  parameter ylinoffset = frame_width >> 2;
  parameter addr_cur_start = yblkoffset * (ymblocks - 1);

  integer clk_match;   // used to adjust clock cycles to match MotionDetection.v

  input          clk;
  input          ena;
  input          rst;
  input          dstrb;
  input          dclr;
  input  [7:0]   din1;
  output [7:0]	  dout1;
  reg    [7:0]	  dout1;
  reg    [31:0]  ybuffer;
  reg    [31:0]  ubuffer;
  reg    [31:0]  vbuffer;
  reg            uvflag;
  output         douten; // data-out enable
  reg            douten;

  reg  [3:0]  state;
  reg	    frame;
  reg  [20:0] input_cnt;
  reg  [9:0]  inx_cnt;
  reg  [9:0]  iny_cnt;
  
  // Motion Detection connections
    output        MD_ena;
    output        MD_rst;
    output [31:0] MD_din1,MD_din2;
    output [3:0]  MD_state;
    output [8:0]  MD_count;

    reg            MD_ena;
    reg            MD_rst;
    reg   [31:0]   MD_din1, MD_din2;
    reg   [31:0]   MD_din1_hold;
    wire  [3:0]    MD_state;
    assign         MD_state = state;
    wire  [8:0]    MD_count;
    assign         MD_count = count;
    input [31:0]   MD_dout;	
    wire  [31:0]   MD_dout;

  // Half Pel Connections
// Inputs

    output        HP_ena;
    output        HP_rst;
    output [31:0] HP_din1;
    output [31:0] HP_din2;
    output [3:0]  HP_state;
    output [8:0]  HP_count;
    output [5:0]  HP_xoffset;
    output [5:0]  HP_yoffset; // minx, miny from full pixel unit

    reg 		  HP_ena;
    reg 		  HP_rst;
    reg [31:0]   HP_din1;
    reg [31:0]   HP_din1_hold;
    reg [31:0]   HP_din1_ee;
    reg [31:0]   HP_din1_e;
    reg [31:0]   HP_din2;
    reg [31:0]   HP_din2_ee;
    reg [31:0]   HP_din2_e;
    wire [3:0]   HP_state;
    assign       HP_state = state;
    wire [8:0]   HP_count;
    assign       HP_count = count;
    reg [5:0]    HP_xoffset;
    reg [5:0]    HP_yoffset; // minx, miny from full pixel unit

// Outputs
    input [31:0] HP_dout;
    wire  [31:0] HP_dout;




// Outputs

  
  
  // RAM Connections 
  // RAM Inputs
  output [16:0] address_0;
  output        cs_0;
  output        we_0;
  output        oe_0;
  output [16:0] address_1;
  output        cs_1;
  output        we_1;
  output        oe_1;
    	
  reg [16:0] address_0;
  reg        cs_0;
  reg        we_0;
  reg        oe_0;
  reg [16:0] address_1;
  reg        cs_1;
  reg        we_1;
  reg        oe_1;

// Outputs


// Bidirs
  reg [31:0] data_0_t;
  reg [31:0] data_1_t;

  inout [31:0] data_0;
  inout [31:0] data_1;

  assign data_0 = (we_0) ? data_0_t : 32'bz;
  assign data_1 = (we_1) ? data_1_t : 32'bz; 
 

// Motion Estimation Registers
  reg [7:0] mblx;			// current macro block x
  reg [7:0] mbly;			// current macro block y
  reg [7:0] mblxd;			// delayed for hp
  reg [7:0] mblyd;			// delayed for hp  
  reg [3:0] mbln;			// 0 - 4 tracks which macroblocks are being
  reg [3:0] mblnd;			// sent to Motiondetection Unit
  reg [3:0] mblndd;			// 0 = cur and 1     1 = 2 and 3
						// 2 = 4 and 5       3 = 6 and 7
						// 4 = 8 and 9 

  reg [6:0] 	mecount;		// 128 counts for 2 macroblocks * 64 mems per 
  reg       	me_datain_flag;
  reg [15:0]   addr_cur;		// address of data in current block
  reg 		frame_cur;

// Half Pel Registers
  reg [7:0] hblx;			// current macro block x
  reg [7:0] hbly;			// current macro block y
  reg [2:0] hp_xcnt;		// 0 - 5 for 18 input/row (4/mem)
  reg [4:0] hp_ycnt;	     // 0 - 17 for row input count
  reg [15:0] hp_addr_cur;
  reg [15:0] hp_addr_cur_hold;
  reg [15:0] hp_addr_srch;
  reg [15:0] hp_addr_srch_d;
  reg        hp_datain_flag;	//
  reg        hp_frame_cur;
  reg	   hp_frame_cur_hold;


// x y input counter and frame control         
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
      input_cnt <=  5'h0;   // 21 bit
	 inx_cnt   <=  0;
      iny_cnt   <=  0;
	 frame     <=  0;
    end
  else 
    if (ena)
      if(input_cnt == frame_height * frame_width * 2 - 1)
	   begin
	     frame <= ~frame;
          input_cnt <=0;
		inx_cnt <= 0;
		iny_cnt <= 0;
	   end
	 else
	   begin
		if (inx_cnt == frame_width * 2 - 1)
		  begin
		    inx_cnt <= 0;
		    iny_cnt <= iny_cnt + 1;
		  end
		else
		  begin
		    inx_cnt <= inx_cnt + 1;
		    iny_cnt <= iny_cnt;
		  end
	     input_cnt <=  input_cnt + 1;
	  end

// input buffer and save
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
	 douten <=  1'b0;
      state  <= 0;
    end
  else if (ena)
    begin
	  // Pixels are assumed to be coming from a camera in
	  // 4:2:2 format 8-bits at a time in Y U Y V order
	  // Pixel info is stored 4 bits at a time
	  // Separating Y U V components

	  // Buffer input for storage
       if (state==0)
         begin
	      if (input_cnt[0:0] == 0)
		   begin
			case (input_cnt[2:1])
			  0:  ybuffer[31:24] <= din1;
			  1:  ybuffer[23:16] <= din1;
			  2:  ybuffer[15:8] <= din1;
			  3:  ybuffer[7:0] <= din1;
			endcase
		   end					    
		else
		  begin
			case (input_cnt[3:1])
			  0:  ubuffer[31:24] <= din1;
			  1:  vbuffer[31:24] <= din1;
			  2:  ubuffer[23:16] <= din1;
			  3:  vbuffer[23:16] <= din1;
			  4:  ubuffer[15:8] <= din1;
			  5:  vbuffer[15:8] <= din1;
		       6:  ubuffer[7:0] <= din1;
			  7:  vbuffer[7:0] <= din1;
			endcase
		  end
				
		// Save buffered data to memory
		// Case statement takes last digit of line count to downsample
		// U and V data.  Last four bits of input_cnt track input
		// data groups YUYV YUYV YUYV YUYV
		// 				   ^ save Y  ^ save Y
		//						  ^ save U (odd lines)
		//             ^ save V (saves on odd lines, first data will
		//                       be last V from previous line)
		address_0[16:16] <= frame;  // alternates each frame    
		casez({iny_cnt[0:0],input_cnt[3:0]})
		  5'b10000:	// save V at 0 after 3 7 9 16
		    begin		// every other line
			 we_0 <= 1;
			 cs_0 <= 1;
			 if (inx_cnt == 0)	// note takes last from first line				
			   address_0[15:0] <= voffset - 1 + (frame_width >> 4) + input_cnt[19:4];
			 else				// others from second line
			   address_0 <= voffset - 1 + input_cnt[19:4];
			 data_0_t <= vbuffer;
		    end
		  5'b??111 :			// save Y every 8 after 0 2 4 6
		    begin
			 we_0 <= 1;
			 cs_0 <= 1;
			 address_0[15:0] <= {input_cnt[19:3]};
			 data_0_t <= ybuffer;
		    end
		  5'b11110:			// save u at 14 after 1 5 9 13 
		    begin		// every other line
		      we_0 <= 1;
		      cs_0 <= 1;					
			 address_0[15:0] <= uoffset + input_cnt[19:4];
			 data_0_t <= ubuffer;
		    end
		  default:
		    begin
		      we_0 <= 0;
			 cs_0 <= 0;							
		    end
		endcase
	  end // if state = 0 (always true now)
    end  // (ena)

// Motion Detection
// Note Write enables for blocks are timed in MD_Block_Ram
always @(posedge clk or negedge rst)
  begin
    we_1 <= 0;
    oe_1 <= 1;
    cs_1 <= 1;
    if (~rst)
      begin
	   MD_din1 <=0;
	   MD_din1_hold <= 0;
	   MD_din2 <=0;
	 end
    else
    if (ena)
    if (mecount[0:0])
      case (mblndd)
         0: begin
 	         MD_din1_hold <= data_1;  // current always valid
		  end
	   1:  begin
	         if (mbly >0)
	           MD_din1_hold <= data_1;	 //block 2 valid on rows > 0
		    else
		      MD_din1_hold <= 32'b10000000100000001000000010000000;
		  end
	   2:  begin
              MD_din1_hold <= data_1;	 // block 5 always valid
		  end
	   3:  begin
	         if (mblx < xmblocks - 1)
	           MD_din1_hold <= data_1;	 // block 6 valid except last col
		    else
		      MD_din1_hold <= 32'b10000000100000001000000010000000;
		  end
	   4:  begin
	         if (mbly < ymblocks - 1)
	           MD_din1_hold <= data_1;	 // block 8 valid except bottom row
		    else
		      MD_din1_hold <= 32'b10000000100000001000000010000000;
		  end
	   default:  MD_din1_hold <= 0;
    	 endcase
    else
      begin
	   MD_din1 <= MD_din1_hold;
        case (mblndd)
          0:  begin
	           if ((mblx > 0) & (mbly >0))
	             MD_din2 <= data_1;	 // block 1 valid if row,col > 1
		      else
		        MD_din2 <= 32'b10000000100000001000000010000000;
  		    end
	     1:  begin
	           if ((mblx < xmblocks - 1) & (mbly >0))
	             MD_din2 <= data_1;	 // block 3 valid row>1 col < max
		      else
		        MD_din2 <= 32'b10000000100000001000000010000000;
		    end
	     2:  begin
	           if (mblx > 0)		// block 4 valid if col > 1
		        MD_din2 <= data_1;
		      else
		        MD_din2 <= 32'b10000000100000001000000010000000;
		    end
	     3:  begin
	           if ((mblx > 0) & (mbly < ymblocks - 1))
	             MD_din2 <= data_1;	 // block 7 valid row < max col > 1
		      else
		        MD_din2 <= 32'b10000000100000001000000010000000;
		    end
	     4:  begin
	           if ((mblx < xmblocks - 1) & (mbly < ymblocks - 1))
	             MD_din2 <= data_1;	 // block 9 valid row < max col < max
		      else
		        MD_din2 <= 32'b10000000100000001000000010000000;
		    end
	     default:  MD_din2 <= 0;
    	   endcase
	 end
  end  // always

// Half Pel data in
// Note Write enables for blocks are timed in MD_Block_Ram
// ensures data from valid position otherwise uses 128
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   HP_din1 <=0;
	   HP_din1 <=0;
	   HP_din2 <=0;
	 end
    else
    if (ena)
    if (~clk2)
      begin
	   if (mblndd == 5)
	     HP_din1 <= data_1;
	   else
	     HP_din1 <= 0;
	 end
    else
	 begin
	   //HP_din1 <= HP_din1_hold;
	   if (mblndd == 5)
	     // test for block in col 0 offset to left	of frame
	     if (({hblx,2'b0} + HP_xoffset[5:2] + hp_xcnt) < 4)
	       HP_din2 <= 32'b10000000100000001000000010000000;
          else  // test for block in last col offset to right
	       if (({hblx,2'b0} + HP_xoffset[5:2] + hp_xcnt) > ({xmblocks,2'b0} + 7))
		    HP_din2 <= 32'b10000000100000001000000010000000;
		  else	// test for blocks on top row
		    if ({hbly,4'b0} + HP_yoffset + hp_ycnt < 16)
		      HP_din2 <= 32'b10000000100000001000000010000000;
	         else  // test for blocks on bottom row
		      if ({hbly,4'b0} + HP_yoffset + hp_ycnt > 95)
		        HP_din2_ee <= 32'b10000000100000001000000010000000;
		      else
		        HP_din2 <= data_1;
	   else
	     HP_din2 <= 0;
	 //HP_din1_e <= HP_din1_ee;
	 //HP_din1 <= HP_din1_e;
  	 //HP_din2_e <= HP_din2_ee;
	 //HP_din2 <= HP_din2_e;
	 end
  end  // always

// Control for hp_xcnt hp_ycnt
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
      hp_xcnt <= 0;
	 hp_ycnt <= 0;
    end
  else 
    if (ena)
      begin
	   case (count)
	     508:
	       begin
		    hp_xcnt <= 0;
	         hp_ycnt <= 0;
		  end
          default:			  
	       begin
		    if (hp_datain_flag)
		      begin
		        if (hp_xcnt == 5)	   // last byte of row 
		          begin
		            hp_xcnt <= 0;
			       hp_ycnt <= hp_ycnt + 1;
		          end
		        else
		          hp_xcnt <= hp_xcnt + 1;
		      end
		  end // case default
	   endcase
	 end
// Control for hp_datain_flag
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
      hp_datain_flag <= 0;
    end
  else 
    if (ena)
      begin
	   case (count)
	      45:  hp_datain_flag <= 0;
	     109:  hp_datain_flag <= 1;    // address increases again at 110
	     157:  hp_datain_flag <= 0;
	     221:  hp_datain_flag <= 1;	// address increases again at 222
	     233:  hp_datain_flag <= 0;
	     509:	 hp_datain_flag <= 1;
	   endcase
	 end


// Control for hp_addr_cur hp_addr_srch
// Writes to Half Pel Unit
// 2 - 49
// 114 - 161
// 226 - 237
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
      hp_addr_cur <= 0;
	 hp_addr_cur_hold <= 0;
	 hp_addr_srch <= 0;
	 hp_addr_srch_d <= 0;
	 hp_frame_cur <= 0;
	 hp_frame_cur_hold <= 0;
    end
  else 
    if (ena)
      begin
	   hp_addr_srch_d <= hp_addr_srch;
        case (count)
	     509:
	       begin  // addr_curr reset at
		    hp_frame_cur_hold <= ~address_1[16:16];  // at 508 this should be in search frame
		    hp_frame_cur <= hp_frame_cur_hold;
 		    hp_addr_cur_hold <= addr_cur;
		    hp_addr_cur <= hp_addr_cur_hold;
		    // Search address starts one pixel up and to the left
		    // of best match from motion detection.
		    // Multiplier could be eliminated by adding register and
		    // adding in steps while decrementing counter
		    // during earlier counts
		    hp_addr_srch <= hp_addr_cur_hold - 4 + HP_xoffset[5:2] 
		                   + HP_yoffset * ylinoffset - {ylinoffset,4'b0};
		  end
	     default:
	       begin
		    if (hp_datain_flag)
		      begin
		        // cur rows of 4
		        if (hp_addr_cur[1:0] == 3) 
		          hp_addr_cur <= hp_addr_cur + ylinoffset - 3;
		        else
		          hp_addr_cur <= hp_addr_cur + 1;
 		        // search rows of 6
		        if(hp_xcnt == 5)
 		          hp_addr_srch <= hp_addr_srch + ylinoffset - 5;
		        else
		          hp_addr_srch <= hp_addr_srch + 1;
		      end
		  end
	   endcase
	 end
// Control for Motion Estimation Data
always @(posedge clk or negedge rst)
  if (~rst)
    begin
      me_datain_flag <= 0;
    end
  else 
    if (ena)
      begin
	   if (iny_cnt[3:0] == 15)	  // last row of macroblock
	     begin
		  if (inx_cnt == frame_width*2 - 1)	   // last byte of row 
		    begin
		      me_datain_flag <= 1;
		    end
		end
	 end

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

  // control for mblx mbly (current macroblock being processed)
  // hblx hbly current macroblock for half pel unit
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   mblx  <= 0;
	   mbly  <= ymblocks - 1; // Start on last row
	   mblxd <= 0;
	   mblyd <= 0;
	   hblx  <= 0; // 2 blocks behind mblx
	   hbly  <= 0;
	   addr_cur <= addr_cur_start;  // address for first macroblock on last row
	 end
    else
    if (ena)
	 if (count == 511)	  // new macroblock every 512 counts  
	   begin
	     mblxd <= mblx;
		mblyd <= mbly;
		hblx <= mblxd;	  // half pel runs one macroblock 
		hbly <= mblyd;	  // behind motion detection unit
	     if (mblx == xmblocks - 1)
	       begin
		    if (mbly == ymblocks - 1)
	       	 begin
			   mbly <= 0;
			   addr_cur <=0;
			 end
		    else
		      begin
			   mbly <= mbly + 1;
			   addr_cur <= addr_cur + yblkoffset - ylinoffset + 4;
			 end	 		    
	         mblx <= 0;
		  end
		else
		  begin
		    mblx <= mblx + 1;
		    addr_cur <= addr_cur + 4;
		  end
	   end
  end  // always

// control for count
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

// control for Motion Detection Enable and rst
always @(negedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   MD_ena <= 0;
        MD_rst <= 0;
	 end
    else
    if (ena)
      begin
	   MD_ena <= 1;
        MD_rst <= 1;
	 end
  end

// control for Half Pel Enable and rst
// Should be changed to not operate during I frames
always @(negedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   HP_ena <= 0;
        HP_rst <= 0;
	 end
    else
    if (ena)
      begin
	   HP_ena <= 1;
        HP_rst <= 1;
	 end
  end

  // control for dout1
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   dout1 <= 0;
	 end
    else
    if (ena)
      begin
	   case (count[1:0])
	     3: dout1 <= MD_dout[31:24];
		0: dout1 <= MD_dout[23:16];
		1: dout1 <= MD_dout[15:8];
		2: dout1 <= MD_dout[7:0];
	   endcase
	 end
  end

  // control for HP_xoffset HP_yoffset
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
        HP_xoffset <= 16; // default to no motion
        HP_yoffset <= 16; // minx, miny from full pixel unit
	 end
    else
    if (ena)
      begin
	   if (count == 508)  // check value
	     begin
	       HP_xoffset <= MD_dout[21:16] - 1; // -1 to get search block
		  HP_yoffset <= MD_dout[5:0] - 1;	 // starting up and over 1
		end
	 end
  end

  // control for mbln, mblnd
always @(posedge clk or negedge rst) // check edge
  begin
    if (~rst)
      begin
	   mbln <= 0;
	   mblnd <= 0;
	   mblndd <= 0;
	 end
    else
    if (ena)
      begin  // need if ~clk2?
	   if (clk2)
	     begin
	       clk_match = 1;
		  mblndd <= mblnd;
			 // 	mblnd <= mbln;	din1 00s at 511 
	       case (count)
	         47-clk_match:	 mbln <= 0;  		// Cur and 1
		    111-clk_match:   mbln <= 5;  		// hp writes
		    159-clk_match:	 mbln <= 1;  		// 2 and 3
		    223-clk_match:   mbln <= 5;  		// hp writes
		    271-clk_match:	 mbln <= 2;  		// 4 and 5
		    335-clk_match:   mbln <= 5;		// hp writes
		    383-clk_match:	 mbln <= 3;  		// 6 and 7
		    447-clk_match:	 mbln <= 4;  		// 8 and 9
		    511-clk_match:   mbln <= 5;  		// hp writes
	       endcase
	     end
	   else
	     begin
	       mblnd <= mbln;	// mblnd <= mbln din2 00s at 
		end
	 end
  end

  // control for frame_cur
always @(posedge clk or negedge rst) // check edge
  begin
    if (~rst)
      begin
	   frame_cur <= 0;
	 end
    else
    if (ena)
      begin  // need if ~clk2?
	   if (~clk2)
	   begin
	     case (count)
	       45:	 
		    begin
		      if(iny_cnt > 15)	 
                    frame_cur <= frame;	 		// first read for cur
		        else						// uses frame currently 
		          frame_cur <= ~frame;	 	// loading unless last
		    end							// row
	     endcase
	   end
	 end
  end

// address control for off chip memories control
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   address_1 <= 0;
	   mecount <= 0;
	 end
    else
    if (ena)
      begin
	   clk_match = 1;
	   if (~clk2)
	     begin
  	       case (count)
  		    47-clk_match:	 // Writes for CUR and 1 for next macroblock
		      begin
			   address_1[16:16] <= frame_cur;
			   address_1[15:0] <= addr_cur;
			   mecount <=0;
		      end
		    159-clk_match:	 // Writes for 2 and 3 for next macroblock
		      begin
			   address_1[16:16] <= ~frame_cur;
			   address_1[15:0] <= addr_cur - yblkoffset;	// Block 2
			   mecount <=0;
		      end
		    271-clk_match:	 // Writes for 4 and 5 for next macroblock
		      begin
			   address_1[16:16] <= ~frame_cur;
			   address_1[15:0] <= addr_cur;  // Block 5 is MD_din1
			   mecount <=0;
		      end
 		    383-clk_match:	 // Writes for 6 and 7 for next macroblock
		      begin
			   address_1[16:16] <= ~frame_cur;
			   address_1[15:0] <= addr_cur + 4; // Block 6
			   mecount <=0;
		      end
 		    447-clk_match:	 // Writes for 8 and 9 for next macroblock
		      begin
			 address_1[16:16] <= ~frame_cur;
			   address_1[15:0] <= addr_cur + yblkoffset;	 // Block 8
			   mecount <=0;
		      end
		     default:
		      begin
			   mecount <= mecount +1;
			   case (mbln)
			     0: address_1[16:16] <= frame_cur;
				5: address_1[16:16] <=  hp_frame_cur;
				default: address_1[16:16] <= ~frame_cur; 
			   endcase
		        case (mbln)
			     0:  begin	 // block 1 to cur
					 if (address_1[1:0] == 3)
					     address_1[15:0] <= address_1[15:0] + yblkoffset + ylinoffset + 1;
					 else
					     address_1[15:0] <= address_1[15:0] + yblkoffset + 5;
			         end
			     1:  begin	// block 3 to 2
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset - 7;
					 else							
					   address_1[15:0] <= address_1[15:0] - 3;				      
			         end
			     2:  begin	// block 4 to 5
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset + 1;
					 else							
					   address_1[15:0] <= address_1[15:0] + 5;
			         end
			     3:  begin	// block 7 to 6
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] - yblkoffset + ylinoffset + 5;
					 else							
					   address_1[15:0] <= address_1[15:0] - yblkoffset + 9;
			         end
			     4:  begin	// block 9 to 8
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset - 7;
					 else							
					   address_1[15:0] <= address_1[15:0] - 3;
			         end
				5:  address_1[15:0] <= hp_addr_cur;
			   endcase
		      end
	       endcase
	     end // if(~clk2)
	   else
	     begin
		  mecount <= mecount +1;
		  case (mbln)
		    5: address_1[16:16] <=  ~hp_frame_cur;
		    default: address_1[16:16] <= ~frame_cur; // search blocks 1 3 5 7 9
		  endcase
		  case (mbln)
		    0:  address_1[15:0] <= address_1[15:0] - yblkoffset - 4;
		    1:  address_1[15:0] <= address_1[15:0] + 4;
		    2:  address_1[15:0] <= address_1[15:0] - 4;
		    3:  address_1[15:0] <= address_1[15:0] + yblkoffset - 8;
		    4:  address_1[15:0] <= address_1[15:0] + 4;
		    5:  address_1[15:0] <= hp_addr_srch_d;
		  endcase
	     end
	 end // if(ena)
  end // always

endmodule
