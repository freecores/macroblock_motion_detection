/////////////////////////////////////////////////////////////////////
////                                                             ////
////  MotionDetection.v                                          ////
////                                                             ////
////  Performs motion estimation for one 16 x 16 macroblock      ////
////  in a 48 x 48 pixel window every 512 clock cycles.          ////
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
module MotionDetection(clk, ena, rst, din1, din2, dout, state, count);
// runs at 1/2 clock speed?
reg clk2;  
parameter COMP =  0;

input [31:0] din1, din2;
input clk, ena, rst;
input [3:0] state;
output [31:0] dout;
input [8:0] count;

reg [31:0] dout;

integer i, j, k, l, m, n, o;

// Motion Estimation Registers
  
  reg [8:0]  diff[0:2][0:15];
  reg [7:0]  diffp[0:15];
  reg [7:0]  diffpd[0:15];
  reg [7:0]  diffm[0:2][0:15];
  reg [7:0]  diffpp[0:2][0:15];
  reg [7:0]  diffmm[0:2][0:15];
  reg [7:0]  diffmd[0:2][0:15];
  reg [10:0] difft[0:2][0:3];

  reg [3:0]  offset;
  wire [7:0]  curt[0:15];
  wire [7:0]  searcht [0:47];

  reg [15:0] sums [0:2][0:11];
  reg [15:0] lowsum[0:1];
  reg        lowflag;
   
  reg [5:0]  minxt,minyt;
  reg [5:0]  oldminx,oldminy;
  reg [3:0]  cursum;
  reg        sumflag;
  reg [5:0]  minx;
  reg [5:0]  miny;

    wire [31:0] DOUTC0;
    wire [31:0] DOUTC1;
    wire [31:0] DOUTC2;
    wire [31:0] DOUTC3;
    wire [31:0] DOUT0;
    wire [31:0] DOUT1;
    wire [31:0] DOUT2;
    wire [31:0] DOUT3;
    wire [31:0] DOUT4;
    wire [31:0] DOUT5;
    wire [31:0] DOUT6;
    wire [31:0] DOUT7;
    wire [31:0] DOUT8;
    wire [31:0] DOUT9;
    wire [31:0] DOUT10;
    wire [31:0] DOUT11;

assign {curt[0],curt[1],curt[2],curt[3]} = DOUTC0;
assign {curt[4],curt[5],curt[6],curt[7]} =  DOUTC1;
assign {curt[8],curt[9],curt[10],curt[11]} =  DOUTC2;
assign {curt[12],curt[13],curt[14],curt[15]} =  DOUTC3;

assign {searcht[0],searcht[1],searcht[2],searcht[3]} = DOUT0;
assign {searcht[4],searcht[5],searcht[6],searcht[7]} = DOUT1;
assign {searcht[8],searcht[9],searcht[10],searcht[11]} = DOUT2;
assign {searcht[12],searcht[13],searcht[14],searcht[15]} = DOUT3;
assign {searcht[16],searcht[17],searcht[18],searcht[19]} = DOUT4;
assign {searcht[20],searcht[21],searcht[22],searcht[23]} = DOUT5;
assign {searcht[24],searcht[25],searcht[26],searcht[27]} = DOUT6;
assign {searcht[28],searcht[29],searcht[30],searcht[31]} = DOUT7;
assign {searcht[32],searcht[33],searcht[34],searcht[35]} = DOUT8;
assign {searcht[36],searcht[37],searcht[38],searcht[39]} = DOUT9;
assign {searcht[40],searcht[41],searcht[42],searcht[43]} = DOUT10;
assign {searcht[44],searcht[45],searcht[46],searcht[47]} = DOUT11;

// Instantiate MD_Block_Ram
    MD_Block_Ram MD_Block_Ram (
        .clk(clk2), 
        .ena(ena), 
        .rst(rst), 
        .din1(din1), 
        .din2(din2), 
        .DOUTC0(DOUTC0), 
        .DOUTC1(DOUTC1), 
        .DOUTC2(DOUTC2), 
        .DOUTC3(DOUTC3), 
        .DOUT0(DOUT0), 
        .DOUT1(DOUT1), 
        .DOUT2(DOUT2), 
        .DOUT3(DOUT3), 
        .DOUT4(DOUT4), 
        .DOUT5(DOUT5), 
        .DOUT6(DOUT6), 
        .DOUT7(DOUT7), 
        .DOUT8(DOUT8), 
        .DOUT9(DOUT9), 
        .DOUT10(DOUT10), 
        .DOUT11(DOUT11), 
        .count(count), 
        .minx(minx), 
        .miny(miny)
        );

  	
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   i = 0;
	   o = 0;
	   for (i = 0; i < 12; i=i+1)
	     begin
		  sums[0][i] <= 0;
		  sums[1][i] <= 0;
		  sums[2][i] <= 0;
		end
	 end
    else
      begin
        if (ena)
          begin
            case (state)
              COMP:
                begin
			   // delay curt 1 cycle to match diffm selection below
                      for (i=0; i < 16; i=i+1)
		              begin
					 diffp[i] <= curt[i];
				    end
                      for (i=0; i < 16; i=i+1)
		              begin
					 diffpd[i] <= diffp[i];
				    end
		        // find differences for this row at three places

			   case (offset)
				8:  begin     // 1 and 3 offset by 16
                          for (i=0; i < 16; i=i+1)
		                 begin
					    diffm[0][i] <= searcht[i+8];
					    diffm[2][i] <= searcht[i+24];
					  end
				    end
				4:  begin     // 1 and 3 offset by 8
                          for (i=0; i < 16; i=i+1)
		                 begin
				         case (minx)
					      8:   begin
					             diffm[0][i] <= searcht[i+4];
					           end
					      16:  begin
					             diffm[0][i] <= searcht[i+12];
					           end
					      24:  begin
					             diffm[0][i] <= searcht[i+20];
					           end
					    endcase
					  end
                          for (i=8; i < 16; i=i+1)
		                 begin
				         case (minx)
					      8:   begin
					             diffm[2][i] <= searcht[i+12];
					           end
					      16:  begin
					             diffm[2][i] <= searcht[i+20];
					           end
					      24:  begin
					             diffm[2][i] <= searcht[i+28];
					           end
					    endcase
					  end
				    end
				2:  begin     // 1 and 3 offset by 4
                          for (i=0; i < 16; i=i+1)
		                 begin
				         case (minx)
					      4:	 begin
					             diffm[0][i] <= searcht[i+2];
					           end
					      8:   begin
					             diffm[0][i] <= searcht[i+6];
					           end
						 12:	 begin
					             diffm[0][i] <= searcht[i+10];
					           end
					      16:  begin
					             diffm[0][i] <= searcht[i+14];
					           end
						 20:	 begin
					             diffm[0][i] <= searcht[i+18];
					           end
					      24:  begin
					             diffm[0][i] <= searcht[i+22];
					           end
						 28:	 begin
					             diffm[0][i] <= searcht[i+26];
					           end
					    endcase
					  end
                          for (i=12; i < 16; i=i+1)
		                 begin
				         case (minx)
					      4:	 begin
					             diffm[2][i] <= searcht[i+6];
					           end
					      8:   begin
					             diffm[2][i] <= searcht[i+10];
					           end
						 12:	 begin
					             diffm[2][i] <= searcht[i+14];
					           end
					      16:  begin
					             diffm[2][i] <= searcht[i+18];
					           end
						 20:	 begin
					             diffm[2][i] <= searcht[i+22];
					           end
					      24:  begin
					             diffm[2][i] <= searcht[i+26];
					           end
						 28:	 begin
					             diffm[2][i] <= searcht[i+30];
					           end
					    endcase
					  end
				    end
				1:  begin     // 1 and 3 offset by 2
                          for (i=0; i < 16; i=i+1)
		                 begin
				         case (minx)
					      2:	 begin
					             diffm[0][i] <= searcht[i+1];
					           end
					      4:	 begin
					             diffm[0][i] <= searcht[i+3];
					           end
						 6:	 begin
					             diffm[0][i] <= searcht[i+5];
					           end
					      8:   begin
					             diffm[0][i] <= searcht[i+7];
					           end
						 10:	 begin
					             diffm[0][i] <= searcht[i+9];
					           end
						 12:	 begin
					             diffm[0][i] <= searcht[i+11];
					           end
						 14:	 begin
					             diffm[0][i] <= searcht[i+13];
					           end
					      16:  begin
					             diffm[0][i] <= searcht[i+15];
					           end
						 18:	 begin
					             diffm[0][i] <= searcht[i+17];
					           end
						 20:	 begin
					             diffm[0][i] <= searcht[i+19];
					           end
						 22:	 begin
					             diffm[0][i] <= searcht[i+21];
					           end
					      24:  begin
					             diffm[0][i] <= searcht[i+23];
					           end
						 26:	 begin
					             diffm[0][i] <= searcht[i+25];
					           end
						 28:	 begin
					             diffm[0][i] <= searcht[i+27];
					           end
						 30:	 begin
					             diffm[0][i] <= searcht[i+29];
					           end
					    endcase
					  end
                          for (i=14; i < 16; i=i+1)
		                 begin
				         case (minx)
					      2:	 begin
					             diffm[2][i] <= searcht[i+3];
					           end
					      4:	 begin
					             diffm[2][i] <= searcht[i+5];
					           end
						 6:	 begin
					             diffm[2][i] <= searcht[i+7];
					           end
					      8:   begin
					             diffm[2][i] <= searcht[i+9];
					           end
						 10:	 begin
					             diffm[2][i] <= searcht[i+11];
					           end
						 12:	 begin
					             diffm[2][i] <= searcht[i+13];
					           end
						 14:	 begin
					             diffm[2][i] <= searcht[i+15];
					           end
					      16:  begin
					             diffm[2][i] <= searcht[i+17];
					           end
						 18:	 begin
					             diffm[2][i] <= searcht[i+19];
					           end
						 20:	 begin
					             diffm[2][i] <= searcht[i+21];
					           end
						 22:	 begin
					             diffm[2][i] <= searcht[i+23];
					           end
					      24:  begin
					             diffm[2][i] <= searcht[i+25];
					           end
						 26:	 begin
					             diffm[2][i] <= searcht[i+27];
					           end
						 28:	 begin
					             diffm[2][i] <= searcht[i+29];
					           end
						 30:	 begin
					             diffm[2][i] <= searcht[i+31];
					           end
					    endcase
					  end
				    end
			   endcase
// copy from 1 and 3 to 1 2 and 3
// 1 is the same
			   for (i=0; i < 16; i=i+1)
		          begin
				  diffmd[0][i] <= diffm[0][i];
				end
// 2 is combination of 1 and 3
			   case (offset)
			   8:  begin
				    for (i=0; i < 8; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[0][i+8];
					   diffmd[1][i+8] <= diffm[2][i];
				      end
			       end
			   4:  begin
				    for (i=0; i < 12; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[0][i+4];
				      end
				    for (i=12; i < 16; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[2][i-4];
				      end
			       end
			   2:  begin
				    for (i=0; i < 14; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[0][i+2];
				      end
				    for (i=14; i < 16; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[2][i-2];
				      end
			       end
			   1:  begin
				    for (i=0; i < 15; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[0][i+1];
				      end
				    for (i=15; i < 16; i=i+1)
		                begin
				        diffmd[1][i] <= diffm[2][i-1];
				      end
			       end
			   endcase
// 3 is combination of 1 and 3
			   case (offset)
			   8:  begin
				    for (i=0; i < 16; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[2][i];
				      end
			       end
			   4:  begin
				    for (i=0; i < 8; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[0][i+8];
				      end
				    for (i=8; i < 16; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[2][i];
				      end
			       end
			   2:  begin
				    for (i=0; i < 12; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[0][i+4];
				      end
				    for (i=12; i < 16; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[2][i];
				      end
			       end
			   1:  begin
				    for (i=0; i < 14; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[0][i+2];
				      end
				    for (i=14; i < 16; i=i+1)
		                begin
				        diffmd[2][i] <= diffm[2][i];
				      end
			       end
			   endcase


		        for (o = 0; o < 3; o = o + 1)
		          begin
                      for (i=0; i < 16; i=i+1)
		              begin					 
					 if (diffpd[i] > diffmd[o][i])
					   begin
					     diffpp[o][i] <= diffpd[i];
						diffmm[o][i] <= diffmd[o][i];
					   end
					 else
					    begin
					     diffpp[o][i] <= diffmd[o][i];
						diffmm[o][i] <= diffpd[i];
					   end
				      diff[o][i] <= diffpp[o][i] - diffmm[o][i];
	                   end  // for i 0 to 15
		          end  // for o 0 to 3

		        // partial sums three times for three tests per row
		        for (o = 0; o < 3; o = o + 1)
		          begin
		            for(i=0; i < 4; i = i + 1)
		              begin
		                k = {i,2'b0};
		                l = k + 1;
		                m = k + 2;
		                n = k + 3;
                          difft[o][i] <= diff[o][k]+diff[o][l]+diff[o][m]+diff[o][n];
		              end
		          end    // o loop

		        // final sums at proper delay repeat three times for three tests per row
		        if (sumflag)
		          begin
		            for (i =0; i < 3; i = i + 1)
		              begin
	                     sums[i][cursum] <= sums[i][cursum] + difft[i][0] + difft[i][1] + difft[i][2] + difft[i][3];
		              end
		          end
			   else
			     if (count == 511)
				  begin
				    for (i =0; i < 3; i = i + 1)
				      begin
				        for (j =0; j < 12; j = j + 1)
		                    begin
	                           sums[i][j] <= 0;
		                    end
					 end
				  end
                end	 // COMP state
            endcase // state

          end  // if ena
	 end	 // if ~rst else
  end  // always

// control for cursum and sumflag , minx, & miny control
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   cursum     <= 0;
	   sumflag    <= 0;
	   minxt      <= 0;
	   minyt      <= 0;
	   oldminx    <= 0;
	   oldminy    <= 0;
	   lowsum[1]  <= 0;
	   lowflag    <= 0;
	   dout       <= 0;
	 end
    else
    if (ena)
      begin
	   i = 5;
	   case (count)		// 16 adds for each offset i from beginning
	      0+i:  begin sumflag <=1; cursum <= 0; end  //0
		16+i:  begin sumflag <=1; cursum <= 1; end //16
		32+i:  begin sumflag <=1; cursum <= 2; end //32
		48+i:  sumflag <=0;

		49+i:  begin
			  lowflag <=1;
			  lowsum[1] <= sums[0][0];
			  minxt <= 8;
			  minyt <= 8;
			end
		50+i:  begin
			  lowsum[1] <= sums[1][0];
			  minxt <= 16;
			  minyt <= 8;
			end
		51+i:  begin
			  lowsum[1] <= sums[2][0];
			  minxt <= 24;
			  minyt <= 8;
			end

		52+i:  begin
			  lowsum[1] <= sums[0][1];
			  minxt <= 8;
			  minyt <= 16;
			end
		53+i:  begin
			  lowsum[1] <= sums[1][1];
			  minxt <= 16;
			  minyt <= 16;
			end
		54+i:  begin
			  lowsum[1] <= sums[2][1];
			  minxt <= 24;
			  minyt <= 16;
			end

		55+i:  begin
			  lowsum[1] <= sums[0][2];
			  minxt <= 8;
			  minyt <= 24;
			end
		56+i:  begin
			  lowsum[1] <= sums[1][2];
			  minxt <= 16;
			  minyt <= 24;
			end
		57+i:  begin
			  lowsum[1] <= sums[2][2];
			  minxt <= 24;
			  minyt <= 24;
			end
 		58+i:  lowflag <=0;

		112+i:  begin sumflag <=1; cursum <= 3; end //112
		128+i:  begin sumflag <=1; cursum <= 4; end //128
		144+i:  begin sumflag <=1; cursum <= 5; end //144
		160+i:  sumflag <=0;
		161+i:  begin
			    oldminx <= minx;
			    oldminy <= miny;
		      end

		162+i:  begin
			  lowflag <=1;
			  lowsum[1] <= sums[0][3];
			  minxt <= oldminx - 4;
			  minyt <= oldminy - 4;
			end
		163+i:  begin
			  lowsum[1] <= sums[1][3];
			  minxt <= oldminx - 0;
			  minyt <= oldminy - 4;
			end
		164+i:  begin
			  lowsum[1] <= sums[2][3];
			  minxt <= oldminx + 4;
			  minyt <= oldminy - 4;
			end

		165+i:  begin
			  lowsum[1] <= sums[0][4];
			  minxt <= oldminx - 4;
			  minyt <= oldminy;
			end
		166+i:  begin
			  lowsum[1] <= sums[1][4];
			  minxt <= oldminx;
			  minyt <= oldminy;
			end
		167+i:  begin
			  lowsum[1] <= sums[2][4];
			  minxt <= oldminx + 4;
			  minyt <= oldminy;
			end

		168+i:  begin
			  lowsum[1] <= sums[0][5];
			  minxt <= oldminx - 4;
			  minyt <= oldminy + 4;
			end
		169+i:  begin
			  lowsum[1] <= sums[1][5];
			  minxt <= oldminx;
			  minyt <= oldminy + 4;
			end
		170+i:  begin
			  lowsum[1] <= sums[2][5];
			  minxt <= oldminx + 4;
			  minyt <= oldminy + 4;
			end
 		171+i:  lowflag <=0;

		224+i:  begin sumflag <=1; cursum <= 6; end //224
		240+i:  begin sumflag <=1; cursum <= 7; end //240
		256+i:  begin sumflag <=1; cursum <= 8; end //256
		272+i:  sumflag <=0;
		273+i:  begin
			    oldminx <= minx;
			    oldminy <= miny;
		      end
		274+i:  begin
			  lowflag <=1;
			  lowsum[1] <= sums[0][6];
			  minxt <= oldminx - 2;
			  minyt <= oldminy - 2;
			end
		275+i:  begin
			  lowsum[1] <= sums[1][6];
			  minxt <= oldminx;
			  minyt <= oldminy - 2;
			end
		276+i:  begin
			  lowsum[1] <= sums[2][6];
			  minxt <= oldminx + 2;
			  minyt <= oldminy - 2;
			end

		277+i:  begin
			  lowsum[1] <= sums[0][7];
			  minxt <= oldminx - 2;
			  minyt <= oldminy;
			end
		278+i:  begin
			  lowsum[1] <= sums[1][7];
			  minxt <= oldminx;
			  minyt <= oldminy;
			end
		279+i:  begin
			  lowsum[1] <= sums[2][7];
			  minxt <= oldminx + 2;
			  minyt <= oldminy;
			end

		280+i:  begin
			  lowsum[1] <= sums[0][8];
			  minxt <= oldminx - 2;
			  minyt <= oldminy + 2;
			end
		281+i:  begin
			  lowsum[1] <= sums[1][8];
			  minxt <= oldminx;
			  minyt <= oldminy + 2;
			end
		282+i:  begin
			  lowsum[1] <= sums[2][8];
			  minxt <= oldminx + 2;
			  minyt <= oldminy + 2;
			end
 		283+i:  lowflag <=0;


		336+i:  begin sumflag <=1; cursum <= 9; end //336
		352+i:  begin sumflag <=1; cursum <= 10; end //352
		368+i:  begin sumflag <=1; cursum <= 11; end //368
		384+i:  sumflag <=0;
		385+i:  begin
			    oldminx <= minx;
			    oldminy <= miny;
		      end

		386+i:  begin
			  lowflag <=1;
			  lowsum[1] <= sums[0][9];
			  minxt <= oldminx - 1;
			  minyt <= oldminy - 1;
			end
		387+i:  begin
			  lowsum[1] <= sums[1][9];
			  minxt <= oldminx;
			  minyt <= oldminy - 1;
			end
		388+i:  begin
			  lowsum[1] <= sums[2][9];
			  minxt <= oldminx + 1;
			  minyt <= oldminy - 1;
			end

		389+i:  begin
			  lowsum[1] <= sums[0][10];
			  minxt <= oldminx - 1;
			  minyt <= oldminy;
			end
		390+i:  begin
			  lowsum[1] <= sums[1][10];
			  minxt <= oldminx;
			  minyt <= oldminy;
			end
		391+i:  begin
			  lowsum[1] <= sums[2][10];
			  minxt <= oldminx + 1;
			  minyt <= oldminy;
			end

		392+i:  begin
			  lowsum[1] <= sums[0][11];
			  minxt <= oldminx - 1;
			  minyt <= oldminy + 1;
			end
		393+i:  begin
			  lowsum[1] <= sums[1][11];
			  minxt <= oldminx;
			  minyt <= oldminy + 1;
			end
		394+i:  begin
			  lowsum[1] <= sums[2][11];
			  minxt <= oldminx + 1;
			  minyt <= oldminy + 1;
			end
 		500:  lowflag <=0;
		507:  dout <= {10'b0,minx,10'b0,miny};
		510:  begin minxt <= 16; minyt <= 16; lowsum[1] <= 0; lowflag <=1; end	
		// Upper Left Corner of Center Block
	     511:  lowflag <= 0;    

 	     default:  cursum <= cursum;
	   endcase
	 end  // if (ena)
  end  //always loop

// control for minx miny lowsum[0] calc
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   lowsum[0] <= 16'b1111111111111111;
	   minx    <= 0;
	   miny    <= 0;
	 end
    else
    if (ena)
      begin
	   if (lowflag)
	     begin
		  if (lowsum[1] < lowsum[0])
	         begin
		      lowsum[0] <= lowsum[1];
		      minx <= minxt; 
		      miny <= minyt;
		    end
		end
	   else
	     begin
		  lowsum[0] <= 16'b1111111111111111;
		  minx <= minx;
		  miny <= miny;
		end
	 end
  end

  // control for offset
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   offset  <= 0;
	 end
    else
    if (ena)
      begin
	   case (count)
	     111: offset  <= 4;
		223: offset  <= 2;
		335: offset  <= 1;
		511: offset  <= 8;
		default:  offset <= offset;
	   endcase
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
endmodule
