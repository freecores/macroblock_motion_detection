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
					 address_0, data_0, cs_0, we_0, oe_0, address_1, data_1, cs_1, we_1, oe_1);
reg clk2;  //1/2 speed clk for data input

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

  parameter clk_match = 1;   // used to adjust clock cycles to match MotionDetection.v

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

    reg           MD_ena;
    reg           MD_rst;
    reg [31:0]    MD_din1, MD_din2;
    wire [3:0]     MD_state;
    assign         MD_state = state;
    wire [8:0]    MD_count;

// Outputs
    input [31:0]  MD_dout;	
    wire  [31:0]  MD_dout;
  
  
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
  reg [15:0] cur [0:15];
  reg [7:0] mblx;			// current macro block x
  reg [7:0] mbly;			// current macro block y
  reg       mfr;			// current frame
  reg [3:0] mbln;			// 0 for curr, 1 - 9 for search blocks

  reg [6:0] mecount;		// 128 counts for 2 macroblocks * 64 mems per 
  reg       me_datain_flag;
  reg [8:0] count;			// 512 cycle counter to synch with Motion block inputs
  reg [15:0] addr_cur;		// address of data in current block
  reg [15:0] addr_search1;
  reg [15:0] addr_search2;

  assign MD_count = count;
// x y input counter and frame control         
always @(posedge clk2 or negedge rst)
  if (~rst)
    begin
      input_cnt <=  5'h0;
	 inx_cnt <= 0;
      iny_cnt <= 0;
	 frame <= 0;
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
	   MD_din2 <=0;
	 end
    else
    if (ena)
    if (mecount[0:0])
      case (mbln)
         0: begin
 	         MD_din1 <= data_1;  // current always valid
		  end
	   1:  begin
	         if (mbly >0)
	           MD_din1 <= data_1;	 //block 2 valid on rows > 0
		    else
		      MD_din1 <= 32'b10000000100000001000000010000000;
		  end
	   2:  begin
              MD_din1 <= data_1;	 // block 5 always valid
		  end
	   3:  begin
	         if (mblx < xmblocks - 1)
	           MD_din1 <= data_1;	 // block 6 valid except last col
		    else
		      MD_din1 <= 32'b10000000100000001000000010000000;
		  end
	   4:  begin
	         if (mbly < ymblocks - 1)
	           MD_din1 <= data_1;	 // block 8 valid except bottom row
		    else
		      MD_din1 <= 32'b10000000100000001000000010000000;
		  end
    	 endcase
    else
      case (mbln)
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
    	 endcase
  end  // always

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

  // control for mfr (motion block frame)
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   mfr  <= 0;
	 end
    else
    if (ena)
	 if (iny_cnt == 15)	  // last row of first macroblock
	   begin
	     if (inx_cnt == frame_width*2 - 1)	   // last byte of row 
	       begin
	         mfr <= frame;
		  end
	   end
  end  // always

  // control for mblx mbly (current macroblock being processed)
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   mblx  <= 0;
	   mbly  <= ymblocks - 1; // Start on last row
	   addr_cur <= addr_cur_start;  // address for first macroblock on last row
	 end
    else
    if (ena)
	 if (count == 511)	  // new macroblock every 512 counts  
	   begin
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
always @(posedge clk2 or negedge rst)
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

// address control for block memories control
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   address_1 <= 0;
	   mbln <=0;
	   mecount <= 0;
        addr_search1 <= 0;
        addr_search2 <= 0;
	 end
    else
    if (ena)
      begin
	   if (~clk2)
	     begin
  	       case (count)
  		    47-clk_match:	 // Writes for CUR and 1 for next macroblock
		      begin
			   if(iny_cnt > 15)	 
                    address_1[16:16] <= frame;	 // first read for cur
		        else						 // uses frame currently 
		          address_1[16:16] <= ~frame;	 // loading unless last
			   address_1[15:0] <= addr_cur;	 // row
			   mecount <=0;
		        mbln <= 0;
		      end
		    159-clk_match:	 // Writes for 2 and 3 for next macroblock
		      begin
			   if(iny_cnt > 15)
                    address_1[16:16] <= ~frame;	 // all others use previous 
		        else						 // frame unless last row
		          address_1[16:16] <= frame;
			   address_1[15:0] <= addr_cur - yblkoffset;	// Block 2
			   mecount <=0;
		        mbln <= 1;
		      end
		    271-clk_match:	 // Writes for 4 and 5 for next macroblock
		      begin
			   address_1[15:0] <= addr_cur;  // Block 5 is MD_din1
			   mecount <=0;
		        mbln <= 2;
		      end
 		    383-clk_match:	 // Writes for 6 and 7 for next macroblock
		      begin
			   address_1[15:0] <= addr_cur + 4; // Block 6
			   mecount <=0;
		        mbln <= 3;
		      end
 		    447-clk_match:	 // Writes for 8 and 9 for next macroblock
		      begin
			   address_1[15:0] <= addr_cur + yblkoffset;	 // Block 8
			   mecount <=0;
		        mbln <= 4;
		      end
		     default:
		      begin
			   mecount <= mecount +1;
		        case (mbln)
			     0:  begin
				      address_1[16:16] <= ~address_1[16:16];  // cur and 1 of search in different frames
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + yblkoffset + ylinoffset + 1;
					 else						     // block 1 to cur
					   address_1[15:0] <= address_1[15:0] + yblkoffset + 5;
			         end
			     1:  begin
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset - 7;
					 else							// block 3 to 2
					   address_1[15:0] <= address_1[15:0] - 3;				      
			         end
			     2:  begin
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset + 1;
					 else							// block 4 to 5
					   address_1[15:0] <= address_1[15:0] + 5;
			         end
			     3:  begin
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] - yblkoffset + ylinoffset + 5;
					 else							// block 7 to 6
					   address_1[15:0] <= address_1[15:0] - yblkoffset + 9;
			         end
			     4:  begin
					 if (address_1[1:0] == 3)
			         	   address_1[15:0] <= address_1[15:0] + ylinoffset - 7;
					 else							// block 9 to 8
					   address_1[15:0] <= address_1[15:0] - 3;
			         end
			   endcase
		      end
	       endcase
	     end // if(clk2)
	   else
	     begin
		  mecount <= mecount +1;
		  case (mbln)
		    0:  begin
		          address_1[16:16] <= ~address_1[16:16];  // cur and 1 of search in different frames
		    		address_1[15:0] <= address_1[15:0] - yblkoffset - 4;
			   end
		    1:  address_1[15:0] <= address_1[15:0] + 4;
		    2:  address_1[15:0] <= address_1[15:0] - 4;
		    3:  address_1[15:0] <= address_1[15:0] + yblkoffset - 8;
		    4:  address_1[15:0] <= address_1[15:0] + 4;
		  endcase
	     end
	 end // if(ena)
  end // always

endmodule
