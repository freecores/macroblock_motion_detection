

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on
module HalfPel(clk, ena, rst, din1, din2, dout, state, count, xoffset, yoffset);

reg clk2;
parameter COMP =  0;

input [31:0] din1, din2;
input clk, ena, rst;
input [3:0] state;
output [31:0] dout;
input [8:0] count;
input [5:0] xoffset,yoffset;

reg [31:0] dout;

integer i, j, k, l, m, n;

  reg [7:0]  cur[0:3][0:15];
  reg [7:0]  diff[0:15];
  reg [7:0]  diffp[0:15];
  reg [7:0]  diffm[0:15];
  reg [10:0] difft[0:3];

  reg [15:0] sums  [0:8];
  reg [15:0] lowsum[0:1];
  reg        lowflag;

  reg [1:0]  minxt,minyt;
  reg [1:0]  oldminx,oldminy;
  reg [3:0]  cursum;
  reg        sumflag;
  reg [1:0]  minx;
  reg [1:0]  miny;

reg [8:0] avgx		    [0:15][0:1];
reg [7:0] avgy          [0:15];		   //
reg [1:0] offx,offy;

reg [31:0] inbuf[0:1][0:2];
wire [1:0]  xshift;				// offset of first byte from mem loc
assign xshift = xoffset[1:0];

reg [7:0] ac_dif[0:15]; // actual difference (twos complement)
reg		save_flag;
reg		save_flag2;	   // delayed 1 cycle

  wire [7:0]  curt[0:15];
  wire [7:0]  searcht [0:17];

    wire [31:0] DOUTC0;
    wire [31:0] DOUTC1;
    wire [31:0] DOUTC2;
    wire [31:0] DOUTC3;
    wire [31:0] DOUT0;
    wire [31:0] DOUT1;
    wire [31:0] DOUT2;
    wire [31:0] DOUT3;
    wire [31:0] DOUT4;

assign {curt[0],curt[1],curt[2],curt[3]} = DOUTC0;
assign {curt[4],curt[5],curt[6],curt[7]} =  DOUTC1;
assign {curt[8],curt[9],curt[10],curt[11]} =  DOUTC2;
assign {curt[12],curt[13],curt[14],curt[15]} =  DOUTC3;

assign {searcht[0],searcht[1],searcht[2],searcht[3]} = DOUT0;
assign {searcht[4],searcht[5],searcht[6],searcht[7]} = DOUT1;
assign {searcht[8],searcht[9],searcht[10],searcht[11]} = DOUT2;
assign {searcht[12],searcht[13],searcht[14],searcht[15]} = DOUT3;
assign {searcht[16],searcht[17]} = DOUT4[31:16];

wire [31:0] HP_din1,HP_din2,HP_din3,HP_din4,HP_din5;
wire [31:0] DOUTC[0:3];

assign HP_din1 = (save_flag2) ? {ac_dif[0],ac_dif[1],ac_dif[2],ac_dif[3]} : inbuf[0][2];
assign HP_din2 = (save_flag2) ? {ac_dif[4],ac_dif[5],ac_dif[6],ac_dif[7]} : inbuf[0][2];
assign HP_din3 = (save_flag2) ? {ac_dif[8],ac_dif[9],ac_dif[10],ac_dif[11]} : inbuf[0][2];
assign HP_din4 = (save_flag2) ? {ac_dif[12],ac_dif[13],ac_dif[14],ac_dif[15]} : inbuf[0][2];
assign HP_din5 = inbuf[1][2];

// Instantiate HP_Block_Ram
    HP_Block_Ram HP_Block_Ram (
        .clk(clk), 
        .ena(ena), 
        .rst(rst), 
        .din1(HP_din1), 
        .din2(HP_din2),
        .din3(HP_din3), 
        .din4(HP_din4),
        .din5(HP_din5),	    
        .DOUTC0(DOUTC0), 
        .DOUTC1(DOUTC1), 
        .DOUTC2(DOUTC2), 
        .DOUTC3(DOUTC3), 
        .DOUT0(DOUT0), 
        .DOUT1(DOUT1), 
        .DOUT2(DOUT2), 
        .DOUT3(DOUT3), 
        .DOUT4(DOUT4), 
        .count(count), 
        .miny(miny)
        );
 
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   i = 0;
        for (j =0; j < 9; j = j + 1)
          begin
            sums[j] <= 0;
          end
	 end
    else
      begin
        if (ena)
          begin
		  // delay curt 3 cycles to match diffm selection below
              for (i=0; i < 16; i=i+1)
		      begin
		        cur[0][i] <= curt[i];
			   cur[1][i] <= cur[0][i];
			   cur[2][i] <= cur[1][i];
			   cur[3][i] <= cur[2][i];
			 end
		  for (i=0; i < 16; i=i+1)
		    begin
		      avgx[i][1] <= avgx[i][0]; // delayed value for Y average
		      case (offx)	    		  // note keep extra bit
		        0:  begin		    	  // for accuracy when averaging Y
			         avgx[i][0] <= ({1'b0,searcht[i]} 
				                 + {1'b0,searcht[i+1]}); 
		            end
		        1:  begin		    
			         avgx[i][0] <= {searcht[i+1],1'b0}; 
		            end
		        2:  begin
			         avgx[i][0] <= ({1'b0,searcht[i+1]} 
				                 + {1'b0,searcht[i+2]}); 			   	    
		            end
		      endcase
		      case (offy)  // sum in y direction -- first sum not used	    
		        0:  begin  // rows 0-16		    
			         avgy[i] <= ({1'b0,avgx[i][0]}
				                 + {1'b0,avgx[i][1]}) >> 2; 
		            end
		        1:  begin  // rows 1-17	(keeps 1 - 16)	    
			         avgy[i] <= avgx[i][1] >> 1; 
		            end
		        2:  begin  // for this case rows 1-17 will be used		    
			         avgy[i] <= ({1'b0,avgx[i][0]}
				                 + {1'b0,avgx[i][1]}) >> 2;  
		            end
		      endcase
		    end  // for i
// save actual differences when final calc is done
		    if (save_flag)
		      begin
			   for (i=0; i < 16; i=i+1)
		          begin
				  // make 9 bit??
				  ac_dif[i] <= cur[3][i] - avgy[i];
				end
			 end
// from here, same subtract as MotionDetection
              for (i=0; i < 16; i=i+1)
		       begin					 
			    if (avgy[i] > cur[3][i])
				 begin
				   diffp[i] <= avgy[i];
				   diffm[i] <= cur[3][i];
				 end
			    else
				 begin
				   diffp[i] <= cur[3][i];
				   diffm[i] <= avgy[i];
				 end
			    diff[i] <= diffp[i] - diffm[i];
	            end  // for i 0 to 15
			// partial sums
               for(i=0; i < 4; i = i + 1)
		       begin
		         k = {i,2'b0};
		         l = k + 1;
		         m = k + 2;
		         n = k + 3;
                   difft[i] <= diff[k]+diff[l]+diff[m]+diff[n];
		       end

		     // final sums at proper delay repeat three times for three tests per row
		     if (sumflag)
		       begin
                   sums[cursum] <= sums[cursum] + difft[0] + difft[1] + difft[2] + difft[3];
		       end
			else
			  if (count == 511)
			    begin
		           for (j =0; j < 9; j = j + 1)
		             begin
	                    sums[j] <= 0;
		             end
			    end
// end same as motion detection calc
		end	// if ena
	 end // if ~rst else
  end // always

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
	   offx 	    <= 0;
	   offy	    <= 0;
	   save_flag  <= 0;
	   save_flag2 <= 0;
	 end
    else
    if (ena)
      begin
	   save_flag2 <= save_flag;
	   i = 1;				//
	   j = 3;				// two avgx reads before calc avgy
	   k = 6;
	   l = 7;
	   case (count)		// 16 adds for each offset i from beginning
	     // 17 rows used to average rows, but only 16 averages summed
		256+i:  offx <=0;
		256+j:  offy <=0;
	     256+l:  begin sumflag <=1; cursum <= 0; end  // -1/2 -1/2
		273+i:  offx <=1;
		273+j:  offy <=0;
		273+k:  sumflag <= 0;
		273+l:  begin sumflag <=1; cursum <= 1; end  //    0 -1/2
		290+i:  offx <=2;
		290+j:  offy <=0;
		290+k:  sumflag <= 0;
		290+l:  begin sumflag <=1; cursum <= 2; end  //  1/2 -1/2
		307+i:  offx <=0;
		307+j:  offy <=1;
		307+k:  sumflag <= 0;
	     307+l:  begin sumflag <=1; cursum <= 3; end  // -1/2    0
		324+i:  offx <=1;
		324+j:  offy <=1;
		324+k:  sumflag <= 0;
		324+l:  begin sumflag <=1; cursum <= 4; end  //    0    0
		341+i:  offx <=2;
		341+j:  offy <=1;
		341+k:  sumflag <= 0;
		341+l:  begin sumflag <=1; cursum <= 5; end  //  1/2    0
		358+i:  offx <=0;
		358+j:  offy <=2;
		358+k:  sumflag <= 0;
	     358+l:  begin sumflag <=1; cursum <= 6; end  // -1/2  1/2
		375+i:  offx <=1;
		375+j:  offy <=2;
		375+k:  sumflag <= 0;
		375+l:  begin sumflag <=1; cursum <= 7; end  //    0  1/2
		392+i:  offx <=2; 
		392+j:  offy <=2;
		392+k:  sumflag <= 0;
		392+l:  begin sumflag <=1; cursum <= 8; end  //  1/2  1/2
		409+k:  sumflag <=0;

		410+k:  begin
			  lowflag <=1;
			  lowsum[1] <= sums[0];
			  minxt <= 0;
			  minyt <= 0;
			end
		411+k:  begin
			  lowsum[1] <= sums[1];
			  minxt <= 1;
			  minyt <= 0;
			end
		412+k:  begin
			  lowsum[1] <= sums[2];
			  minxt <= 2;
			  minyt <= 0;
			end

		413+k:  begin
			  lowsum[1] <= sums[3];
			  minxt <= 0;
			  minyt <= 1;
			end
		414+k:  begin
			  lowsum[1] <= sums[4];
			  minxt <= 1;
			  minyt <= 1;
			end
		415+k:  begin
			  lowsum[1] <= sums[5];
			  minxt <= 2;
			  minyt <= 1;
			end

		416+k:  begin
			  lowsum[1] <= sums[6];
			  minxt <= 0;
			  minyt <= 2;
			end
		417+k:  begin
			  lowsum[1] <= sums[7];
			  minxt <= 1;
			  minyt <= 2;
			end
		418+k:  begin
			  lowsum[1] <= sums[8];
			  minxt <= 2;
			  minyt <= 2;
			end

		427:  begin offx <=minx; offy <=miny; end   
		433:  begin save_flag <= 1; end   
		449:  begin save_flag <= 0; end

 		507:  lowflag <=0;  // resets minx,miny

		510:  begin minxt <= 16; minyt <= 16; lowsum[1] <= 0; lowflag <=1; end	
		// Upper Left Corner of Center Block
	     511:  lowflag <= 0;    
 	     default:  begin
				  
				end
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

// control for dout
always @(negedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   dout    <= 0;
	 end
    else
    if (ena)
      begin
	   if (count < 64)
	     case (count[1:0])
		  0: dout <= DOUTC0;
		  1: dout <= DOUTC1;
		  2: dout <= DOUTC2;
		  3: dout <= DOUTC3;
		endcase
	     
	   else
		case (count)  // Final Motion Vector in 1/2 pixels
				    // + 2x1/2 since 1 was subtracted before
		508:  begin   // - 1/2 since minx 0 >> -1/2 1 >> 0 2 >> + 1/2 
			   dout[31:23] <= 0;
			   dout[22:16] <= ({5'h00,minx}+{xoffset,1'b0}+7'h01);	
			   dout[15:07] <= 0;
			   dout[06:00] <= ({5'h00,miny}+{yoffset,1'b0}+7'h01);
			 end
		//dout <= {9'h000,({4'h0,minx}+{xoffset,1'b0}-1),9'h000,({4'h0,miny}+{yoffset,1'b0}-1)};
		endcase
	 end
  end



// load cur macroblock 16x16
// requires 64 32-bit memory reads 
// could be done with load to MotionDetection.v
// but this requires buffering to wait for motion vectors
// or do separate load

// control for input buffers -- adjusts to account for offsets from 4 byte memory

always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   inbuf[0][0] <= 0;
	   inbuf[0][1] <= 0;
	   inbuf[1][0] <= 0;
	   inbuf[1][1] <= 0;
	   inbuf[0][2] <= 0;
	   inbuf[1][2] <= 0;
	 end
    else
    if (ena)
      begin
	   inbuf[0][0] <= din1;
	   inbuf[1][0] <= din2;
	   inbuf[0][1] <= inbuf[0][0];
	   inbuf[1][1] <= inbuf[1][0];
	   inbuf[0][2] <= inbuf[0][1];
	   case (xshift)
	     0:  begin
		      //inbuf[0][2] <= inbuf[0][1];
			 inbuf[1][2] <= inbuf[1][1];
		    end
	     1:  begin
		      //inbuf[0][2] <= {inbuf[0][1][23:0],inbuf[0][0][31:24]};
			 inbuf[1][2] <= {inbuf[1][1][23:0],inbuf[1][0][31:24]};
		    end
	     2:  begin
		      //inbuf[0][2] <= {inbuf[0][1][15:0],inbuf[0][0][31:16]};
			 inbuf[1][2] <= {inbuf[1][1][15:0],inbuf[1][0][31:16]};
		    end
	     3:  begin
		      //inbuf[0][2] <= {inbuf[0][1][7:0],inbuf[0][0][31:8]};
			 inbuf[1][2] <= {inbuf[1][1][7:0],inbuf[1][0][31:8]};
		    end
	   endcase
	 end
  end


// load offset_x 0-3 to specify location of upper left corner of search block
// versus memory location

// load search block 18x18
// requires 108 32 bit memory reads 108 = 18 * 6



// compute total difference for each block
// 16 rows x 9 positions = 144 cycles



// recompute differences for best match and output differences
// output minimum diff matrix and half pel motion vectors

// U and V data still needs to be calculated
// Since U and V data are 1/2 of Y data, use full pixel data?  
// load U and V data requires 2x 10x10 blocks each =  100 reads

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
