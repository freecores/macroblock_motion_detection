/////////////////////////////////////////////////////////////////////
////                                                             ////
////  HB_Block_Ram.v                                             ////
////                                                             ////
////  Manages Block Ram Resources for HalfPel.v                  ////
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
module HP_Block_Ram(clk, ena, rst, din1, din2, din3, din4, din5,
				DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3, DOUT4,
				count, miny);

reg clk2;

input [31:0] din1, din2, din3, din4, din5;
input clk, ena, rst;
output [31:0]		DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3, DOUT4;

wire [31:0]		DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3, DOUT4;

input [8:0] count;

input [1:0] miny;

integer i;
				
reg PAGE;
reg ioflag, ioflag2;  		// used for address control
reg srch_we_flag;	// used to skip clock when adjusting byte locations
reg cur_we_flag;

reg  WE[0:4];
reg  [5:0] ADDR;
wire [7:0] ADDRA;
wire [7:0] ADDRB;

assign ADDRA[7:1] = {PAGE,ADDR};
assign ADDRB[7:1] = {PAGE,ADDR};
assign ADDRA[0:0] = 0;
assign ADDRB[0:0] = 1;
wire [15:0] DINA[0:11], DINB[0:11];

assign {DINA[0],DINB[0]} = din5;
assign {DINA[1],DINB[1]} = din5;
assign {DINA[2],DINB[2]} = din5;
assign {DINA[3],DINB[3]} = din5;
assign {DINA[4],DINB[4]} = din5;
 
wire [15:0] DOUTA[0:11];
wire [15:0] DOUTB[0:11];

genvar t;
//
generate
for (t=0; t<5; t=t+1)
begin:searchram		// note operates on CLK2 (half speed)
RAMB4_S16_S16 mem(.WEA(WE[t]), .WEB(WE[t]), .ENA(1'b1), .ENB(1'b1), .RSTA(1'b0), .RSTB(1'b0), .CLKA(clk2), .CLKB(clk2),
.ADDRA(ADDRA), .ADDRB(ADDRB), .DIA(DINA[t]), .DIB(DINB[t]), .DOA(DOUTA[t]), .DOB(DOUTB[t]));
end
endgenerate

reg  WEC[0:3];
reg  WEC2;
reg WECS[0:3]; // allows sharing functions for RAM blocks

reg  [5:0] ADDRC;
reg  [5:0] ADDRC2;

wire [7:0] ADDRAC, ADDRBC;
assign ADDRAC = (clk2) ? {PAGE,ADDRC,1'b0} :  {PAGE,ADDRC2,1'b0};
assign ADDRBC = (clk2) ? {PAGE,ADDRC,1'b1} :  {PAGE,ADDRC2,1'b1};
wire [15:0] DINAC[0:3], DINBC[0:3];
assign {DINAC[0],DINBC[0]} = din1;
assign {DINAC[1],DINBC[1]} = din2;
assign {DINAC[2],DINBC[2]} = din3;
assign {DINAC[3],DINBC[3]} = din4;
wire [15:0] DOUTAC[0:3];
wire [15:0] DOUTBC[0:3];

//
generate
for (t=0; t<4; t=t+1)
begin:curram 		    // note operates on clk
RAMB4_S16_S16 mem(.WEA(WECS[t]), .WEB(WECS[t]), .ENA(1'b1), .ENB(1'b1), .RSTA(1'b0), .RSTB(1'b0), .CLKA(clk),	.CLKB(clk),
.ADDRA(ADDRAC), .ADDRB(ADDRBC), .DIA(DINAC[t]), .DIB(DINBC[t]), .DOA(DOUTAC[t]), .DOB(DOUTBC[t]));
end
endgenerate

//defparam mem_1.WRITE_MODE = "READ_FIRST";
//defparam mem_2.WRITE_MODE = "READ_FIRST";
//defparam mem_3.WRITE_MODE = "READ_FIRST";

assign DOUTC0 = {DOUTAC[0],DOUTBC[0]};
assign DOUTC1 = {DOUTAC[1],DOUTBC[1]};
assign DOUTC2 = {DOUTAC[2],DOUTBC[2]};
assign DOUTC3 = {DOUTAC[3],DOUTBC[3]};

assign DOUT0 = {DOUTA[0],DOUTB[0]};
assign DOUT1 = {DOUTA[1],DOUTB[1]};
assign DOUT2 = {DOUTA[2],DOUTB[2]};
assign DOUT3 = {DOUTA[3],DOUTB[3]};

assign DOUT4 = {DOUTA[4],DOUTB[4]};

// address control for block memories control
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   srch_we_flag  <= 0;
	   cur_we_flag <= 0;
	   ADDR <= 0;		   
	   ADDRC   <= 0;		   
	   ioflag  <= 1;		   
	   PAGE    <= 0;
	   for (i = 0; i < 4; i = i + 1)		   
	     begin
		  WEC[i] <= 0;
		end
	 end					   
    else					   
    if (ena)				   
      begin				   
	   case (count)		   
		1:begin
		    WEC[0]  <= 1;	// WEC buffered
		  end	
		2:  
		  begin
		    WEC[0]  <= 0;	// Next 48 clocks write current
		    WEC[1]  <= 1;
		    WE[0]   <= 1;	// Next 48 clocks write 40 mems for search
		    PAGE    <= PAGE;  
		    ADDR 	  <= 0;   
	   	    ADDRC   <= 0;	
		    ioflag  <= 0;
		  end
		49:
		  begin
		    WEC[3] <= 0;
		    WE[4]  <= 0;
		  end

		113:
		  begin
 		    WEC[0]  <= 1;	// WEC buffered
		  end
		114:  
		  begin
		    WEC[0]  <= 0;	// Next 16 clocks write current
		    WEC[1]  <= 1;
		    WE[0]   <= 1;	// Next 48 clocks write 40 mems for search
		    PAGE    <= PAGE;  
		    ADDR	  <= 8;   
	   	    ADDRC   <= 12;	
		    ioflag  <= 0;
		  end
		161:
		  begin
		    WEC[3] <= 0;
		    WE[4]  <= 0;
		  end

		226:  
		  begin
		    WE[0]   <= 1;	// Next 12 clocks write 10 mems for search	
		    PAGE    <= PAGE;  
		    ADDR    <= 16;   
	   	    ADDRC   <= 0;	
		    ioflag  <= 0;
		  end
		237:
		  begin
		    WE[4] <= 0;
		  end


	     256:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 0;   // Next 17 clocks read rows 0 - 16 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		273:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 0;   // Next 17 clocks read rows 0 - 16 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		290:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 0;   // Next 17 clocks read rows 0 to 16 of Search Block
	   	    ADDRC   <= 0;	       // Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end

		307:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 to 17 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		324:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 to 17 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		341:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 to 17 of Search Block
 	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end

		358:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 - 17 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		375:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 - 17 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		392:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR    <= 1;   // Next 17 clocks read rows 1 - 17 of Search Block
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end

		429:
		  begin
		    PAGE    <= PAGE;
		    if(miny == 0)	 // Next 17 clocks read 17 rows of Search Block
		      ADDR    <= 0;
		    else
		      ADDR    <= 1;	    
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end

		default:
		  begin		    // Cur write same as MD
		    for (i = 0; i < 4; i = i + 1)
		    begin
		      if (WEC[i])
		      begin
		        WEC[i] <= 0;
			   if (i == 3)
			     WEC[0] <= 1;
			   else
			    WEC[i+1] <= 1;
		      end
		    end
		    if (WEC[3])
		      cur_we_flag <= 1;
		    if (srch_we_flag)
		      begin
		        WE[0] <= 1;
			   srch_we_flag  <= 0;
			 end
		    else
		      begin
		        for (i = 0; i < 5; i = i + 1)
 		          begin
 		            if (WE[i])
		              begin
		                WE[i] <= 0;
			           if (i[2:2] == 0)	 // skip one clock after WE[4]
 			             WE[i+1] <= 1;
					 else
					   srch_we_flag <= 1;
		              end
		          end
			 end

		    PAGE    <= PAGE;
		    if (ioflag)
		      begin  
			   ADDR    <= ADDR + 1;   
	   	        ADDRC   <= ADDRC + 1;
			 end
		    else
		      begin
		        if (cur_we_flag)	// every 4 counts
		          begin  			
	   	            ADDRC   <= ADDRC + 1;
				  cur_we_flag <= 0;
			     end
			   if (srch_we_flag)   // 6 clocks per line write for 5 inputs
			     begin
			       ADDR    <= ADDR + 1;   
				end
			 end
		  end // default case
	   endcase
	 end

  end

// control for WEC2 and ADDRC2
// used to write difference array in off clocks
// read values for output in off clocks
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   WEC2  <= 0;
	   ADDRC2  <= 20;
	   ioflag2 <= 0;
	 end
    else
    if (ena)
      begin
	   case (count)
	     434:  begin  ioflag2 <= 1; WEC2 <= 1; ADDRC2 <= 20;  end 
		450:  WEC2 <= 0;
		510:  begin ioflag2 <= 0; ADDRC2 <= 20; end
	     default:
		    if (ioflag2)
		      begin  
	   	        ADDRC2   <= ADDRC2 + 1;
			 end
		    else
		      begin
		        if (count[1:0] == 2)
		          begin  
	   	            ADDRC2   <= ADDRC2 + 1;
			     end
			 end
	   endcase
	 end
  end

// control for WECS
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   for (i = 0; i < 4; i = i + 1)		   
	     begin
		  WECS[i] <= 0;
		end
	 end
    else
    if (ena)
      begin
	   if (clk2)
	     begin
	       for (i = 0; i < 4; i = i + 1)		   
	         begin
		      WECS[i] <= WEC2;
		    end
		end
	   else
	     begin
	       for (i = 0; i < 4; i = i + 1)		   
	         begin
		      WECS[i] <= WEC[i];
		    end
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

endmodule
