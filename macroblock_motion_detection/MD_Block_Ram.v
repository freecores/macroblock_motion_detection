/////////////////////////////////////////////////////////////////////
////                                                             ////
////  MD_Block_Ram.v                                             ////
////                                                             ////
////  Manages Block Ram Resources for Motion.v                   ////
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
module MD_Block_Ram(clk, ena, rst, din1, din2,
				DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3,
				DOUT4, DOUT5, DOUT6, DOUT7,
				DOUT8, DOUT9, DOUT10, DOUT11,
				count, minx, miny);

input [31:0] din1, din2;
input clk, ena, rst;
output [31:0]		DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3,
				DOUT4, DOUT5, DOUT6, DOUT7,
				DOUT8, DOUT9, DOUT10, DOUT11; 

wire [31:0]		DOUTC0, DOUTC1, DOUTC2, DOUTC3,
				DOUT0, DOUT1, DOUT2, DOUT3,
				DOUT4, DOUT5, DOUT6, DOUT7,
				DOUT8, DOUT9, DOUT10, DOUT11;

input [8:0] count;



input [5:0] minx;
input [5:0] miny;

integer i;
				
reg PAGE;
reg ioflag;  // used for address control

reg  WE[0:11];
reg  [5:0] ADDR[0:2];
wire [7:0] ADDRA[0:2];
wire [7:0] ADDRB[0:2];

assign ADDRA[0][7:1] = {PAGE,ADDR[0]};
assign ADDRB[0][7:1] = {PAGE,ADDR[0]};
assign ADDRA[0][0:0] = 0;
assign ADDRB[0][0:0] = 1;
assign ADDRA[1][7:1] = {PAGE,ADDR[1]};
assign ADDRB[1][7:1] = {PAGE,ADDR[1]};
assign ADDRA[1][0:0] = 0;
assign ADDRB[1][0:0] = 1;
assign ADDRA[2][7:1] = {PAGE,ADDR[2]};
assign ADDRB[2][7:1] = {PAGE,ADDR[2]};
assign ADDRA[2][0:0] = 0;
assign ADDRB[2][0:0] = 1;
wire [15:0] DINA[0:11], DINB[0:11];

assign {DINA[0],DINB[0]} = din2;
assign {DINA[1],DINB[1]} = din2;
assign {DINA[2],DINB[2]} = din2;
assign {DINA[3],DINB[3]} = din2;
assign {DINA[4],DINB[4]} = din1;
assign {DINA[5],DINB[5]} = din1;
assign {DINA[6],DINB[6]} = din1;
assign {DINA[7],DINB[7]} = din1;
assign {DINA[8],DINB[8]} = (ADDR[2][4:4]) ? din1 : din2;
assign {DINA[9],DINB[9]} = (ADDR[2][4:4]) ? din1 : din2;
assign {DINA[10],DINB[10]} = (ADDR[2][4:4]) ? din1 : din2;
assign {DINA[11],DINB[11]} = (ADDR[2][4:4]) ? din1 : din2;
 
wire [15:0] DOUTA[0:11];
wire [15:0] DOUTB[0:11];

genvar t;
//
generate
for (t=0; t<12; t=t+1)
begin:searchram
RAMB4_S16_S16 mem(.WEA(WE[t]), .WEB(WE[t]), .ENA(1'b1), .ENB(1'b1), .RSTA(1'b0), .RSTB(1'b0), .CLKA(clk), .CLKB(clk),
.ADDRA(ADDRA[t >> 2]), .ADDRB(ADDRB[t >> 2]), .DIA(DINA[t]), .DIB(DINB[t]), .DOA(DOUTA[t]), .DOB(DOUTB[t]));
end
endgenerate

reg  WEC[0:3];
reg  [5:0] ADDRC;
wire [7:0] ADDRAC, ADDRBC;
assign ADDRAC[7:1] = {PAGE,ADDRC};
assign ADDRBC[7:1] = {PAGE,ADDRC};
assign ADDRAC[0:0] = 0;
assign ADDRBC[0:0] = 1;
wire [15:0] DINAC[0:3], DINBC[0:3];
assign {DINAC[0],DINBC[0]} = din1;
assign {DINAC[1],DINBC[1]} = din1;
assign {DINAC[2],DINBC[2]} = din1;
assign {DINAC[3],DINBC[3]} = din1;
wire [15:0] DOUTAC[0:3];
wire [15:0] DOUTBC[0:3];

//
generate
for (t=0; t<4; t=t+1)
begin:curram 
RAMB4_S16_S16 mem(.WEA(WEC[t]), .WEB(WEC[t]), .ENA(1'b1), .ENB(1'b1), .RSTA(1'b0), .RSTB(1'b0), .CLKA(clk),	.CLKB(clk),
.ADDRA(ADDRAC), .ADDRB(ADDRBC), .DIA(DINAC[t]), .DIB(DINBC[t]), .DOA(DOUTAC[t]), .DOB(DOUTBC[t]));
end
endgenerate

assign DOUTC0 = {DOUTAC[0],DOUTBC[0]};
assign DOUTC1 = {DOUTAC[1],DOUTBC[1]};
assign DOUTC2 = {DOUTAC[2],DOUTBC[2]};
assign DOUTC3 = {DOUTAC[3],DOUTBC[3]};

assign DOUT0 = {DOUTA[0],DOUTB[0]};
assign DOUT1 = {DOUTA[1],DOUTB[1]};
assign DOUT2 = {DOUTA[2],DOUTB[2]};
assign DOUT3 = {DOUTA[3],DOUTB[3]};

assign DOUT4 = {DOUTA[4],DOUTB[4]};
assign DOUT5 = {DOUTA[5],DOUTB[5]};
assign DOUT6 = {DOUTA[6],DOUTB[6]};
assign DOUT7 = {DOUTA[7],DOUTB[7]};

assign DOUT8 = {DOUTA[8],DOUTB[8]};
assign DOUT9 = {DOUTA[9],DOUTB[9]};
assign DOUT10 = {DOUTA[10],DOUTB[10]};
assign DOUT11 = {DOUTA[11],DOUTB[11]};

// address control for block memories control
always @(posedge clk or negedge rst)
  begin
    if (~rst)
      begin
	   ADDR[0] <= 0;		   // Block Memories
	   ADDR[1] <= 0;		   // 0 1 2 3 4 5 6 7 8 9 10 11
	   ADDR[2] <= 0;		   // MacroBlocks				Addresses
	   ADDRC   <= 0;		   //
	   ioflag  <= 1;		   // 1 1 1 1 2 2 2 2 3 3 3 3		0 - 15
	   PAGE    <= 0;		   //
	 end					   // 4 4 4 4 5 5 5 5 6 6 6 6      16 - 23
    else					   //
    if (ena)				   // 7 7 7 7 8 8 8 8 9 9 9 9      24 - 47
      begin				   //  
	   case (count)		   // Addr[0] Addr[1] Addr[2]
	     15:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= 16;   // Next 16 clocks read rows 16 - 31 of Search Block
	   	    ADDR[1] <= 16;   // For first 3 checks
	   	    ADDR[2] <= 16;	
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		31:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= 24;   // Next 16 clocks read rows 24 - 39 of Search Block
	   	    ADDR[1] <= 24;   // For first 3 checks
	   	    ADDR[2] <= 24;	
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		47:	 // Writes for CUR and 1 for next macroblock
		  begin
		    WEC[0]  <= 1;
		    WE[0]   <= 1;
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= 0;   
	   	    ADDR[1] <= 0;   
	   	    ADDR[2] <= 0;	
	   	    ADDRC   <= 0;
		    ioflag  <= 0;
		  end
		111:
		  begin
		    WEC[3]  <= 0;
		    WE[3]   <= 0;
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= miny - 4;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny - 4;   // For second 3 checks
	   	    ADDR[2] <= miny - 4;	
	   	    ADDRC   <= 0;	       // Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		127:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny;   // For second 3 checks
	   	    ADDR[2] <= miny;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		143:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny + 4;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny + 4;   // For second 3 checks
	   	    ADDR[2] <= miny + 4;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		159:	 // Writes for 2 and 3 for next macroblock
		  begin
		    WE[4]   <= 1;
		    WE[8]   <= 1;
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= 0;   
	   	    ADDR[1] <= 0;   
	   	    ADDR[2] <= 0;	
	   	    ADDRC   <= 0;
		    ioflag  <= 0;
		  end
		223:
		  begin
		    WE[7]   <= 0;
		    WE[11]  <= 0;
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= miny - 2;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny - 2;   // For third 3 checks
	   	    ADDR[2] <= miny - 2;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		239:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny;   // For third 3 checks
	   	    ADDR[2] <= miny;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		255:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny + 2;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny + 2;   // For third 3 checks
	   	    ADDR[2] <= miny + 2;	
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		271:	 // Writes for 4 and 5 for next macroblock
		  begin
		    WE[0]   <= 1;
		    WE[4]   <= 1;		    
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= 16;   
	   	    ADDR[1] <= 16;   
	   	    ADDR[2] <= 16;	
	   	    ADDRC   <= 0;
		    ioflag  <= 0;
		  end
		335:
		  begin
		    WE[3]   <= 0;
		    WE[7]   <= 0;
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= miny - 1;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny - 1;   // For fourth 3 checks
	   	    ADDR[2] <= miny - 1;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		351:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny;   // For fourth 3 checks
	   	    ADDR[2] <= miny;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		367:
		  begin
		    PAGE    <= PAGE;			 
		    ADDR[0] <= miny + 1;   // Next 16 clocks read 16 rows of Search Block
	   	    ADDR[1] <= miny + 1;   // For fourth 3 checks
	   	    ADDR[2] <= miny + 1;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
 		383:	 // Writes for 6 and 7 for next macroblock
		  begin
		    WE[8]   <= 1;	// for block 6
		    WE[0]   <= 1;	// for block 7
		    PAGE    <= ~PAGE;			 
		    ADDR[0] <= 32;  // for block 7   
	   	    ADDR[1] <= 0;   // doesn't matter
	   	    ADDR[2] <= 16;	// for block 6
	   	    ADDRC   <= 0;
		    ioflag  <= 0;
		  end
 		447:	 // Writes for 8 and 9 for next macroblock
		  begin
		    WE[11]  <= 0;
		    WE[3]   <= 0;
		    WE[4]   <= 1;
		    WE[8]   <= 1;
		    PAGE    <= PAGE;			 
		    ADDR[0] <= 0;   
	   	    ADDR[1] <= 32;   
	   	    ADDR[2] <= 32;	
	   	    ADDRC   <= 0;
		    ioflag  <= 0;
		  end
		511:  
		  begin
		    WE[7]   <= 0;
		    WE[11]  <= 0;
		    PAGE    <= PAGE;  // Dont switch here -- Read starts on page that was just written			 
		    ADDR[0] <= 8;   // Next 16 clocks read rows 8 - 23 of Search Block
	   	    ADDR[1] <= 8;   // For first 3 checks
	   	    ADDR[2] <= 8;
	   	    ADDRC   <= 0;	// Next 16 clocks read 16 rows of Current Block
		    ioflag  <= 1;
		  end
		default:
		  begin
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
		    for (i = 0; i < 12; i = i + 1)
		    begin
		      if (WE[i])
		      begin
		        WE[i] <= 0;
			   if (i[1:0] == 3)
			     WE[i-3] <= 1;
			   else
			    WE[i+1] <= 1;
		      end
		    end
		    PAGE    <= PAGE;
		    if (ioflag)
		      begin  
			   ADDR[0] <= ADDR[0] + 1;   
	   	        ADDR[1] <= ADDR[1] + 1;   
	   	        ADDR[2] <= ADDR[2] + 1;
	   	        ADDRC   <= ADDRC + 1;
			 end
		    else
		      if (count[1:0] == 3)
		        begin  
			     ADDR[0] <= ADDR[0] + 1;   
	   	          ADDR[1] <= ADDR[1] + 1;   
	   	          ADDR[2] <= ADDR[2] + 1;
	   	          ADDRC   <= ADDRC + 1;
			   end
		  end
	   endcase
	 end

  end


endmodule
