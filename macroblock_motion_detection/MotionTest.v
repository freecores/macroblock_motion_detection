/////////////////////////////////////////////////////////////////////
////                                                             ////
////  MotionTest.v                                               ////
////                                                             ////
////  Test Bench for MotionDetection.v                           ////
////  This file inputs a current macroblock and nine             ////
////  test macroblocks to be searched for the best match         ////
////  every 512 cycles to be tested in the next 521 cycles.      ////
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
module MotionDetection_MotionTest_v_tf();
// DATE:     22:50:06 09/11/2004 
// MODULE:   MotionDetection
// DESIGN:   MotionDetection
// FILENAME: MotionTest.v
// PROJECT:  NTSCtoMacroblock
// VERSION:  

integer i,j;
reg clk2;  //half speed clock
// Inputs
    reg clk;
    reg ena;
    reg rst;
    reg [31:0] din1, din2;
    reg [3:0] state;
    reg [8:0] count;
    reg [31:0] curinput;
    reg [3:0]  curcount;


// Outputs
    wire [31:0] dout;


// Bidirs

// Instantiate the UUT
    MotionDetection uut (
        .clk(clk), 
        .ena(ena), 
        .rst(rst), 
        .din1(din1),
	   .din2(din2), 
        .dout(dout), 
        .state(state),
	   .count(count)
        );


        initial begin
            clk <= 0;
            ena <= 0;
            rst <= 0;
		  @(posedge clk);
		  ena <= 1;
		  rst <= 1;
		  @(posedge clk);
            state = 0;
		  for (j = 0; j < 10; j = j + 1)     // Initilization + 9 tests
		  begin
		    for (i = 0; i < 512; i = i + 1)  // 512 counts per test
		      begin
	             @(posedge clk);			  // Two clocks per count
		        @(posedge clk);
		      end
		  end
		  $stop;
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

always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
	   curcount  <= 0;
	   curinput  <= {8'd1,8'd1,8'd1,8'd1};
	 end
    else
    if (ena)
      begin
	   if (count == 511)
	     begin
		  curcount <= curcount + 1;
		  case (curcount)
		    0: curinput  <= {8'd2,8'd2,8'd2,8'd2};
		    1: curinput  <= {8'd3,8'd3,8'd3,8'd3};
		    2: curinput  <= {8'd4,8'd4,8'd4,8'd4};
		    3: curinput  <= {8'd5,8'd5,8'd5,8'd5};
		    4: curinput  <= {8'd6,8'd6,8'd6,8'd6};
		    5: curinput  <= {8'd7,8'd7,8'd7,8'd7};
		    6: curinput  <= {8'd8,8'd8,8'd8,8'd8};
		    7: curinput  <= {8'd9,8'd9,8'd9,8'd9};
		  endcase
		end
	 end
  end


// address control for block memories control
always @(posedge clk2 or negedge rst)
  begin
    if (~rst)
      begin
        din1 <= 0;
	   din2 <= 0;
	 end
    else
    if (ena)
      begin
  	   case (count)
  		47:	 // Writes for CUR and 1 for next macroblock
		     begin
        		  din1 <= curinput;
	            din2 <= {8'd1,8'd1,8'd1,8'd1};
		     end
		159:	// Writes for 2 and 3 for next macroblock
		     begin
        		  din1 <= {8'd2,8'd2,8'd2,8'd2};
	            din2 <= {8'd3,8'd3,8'd3,8'd3};
		     end
		271:	// Writes for 4 and 5 for next macroblock
		     begin
        		  din2 <= {8'd4,8'd4,8'd4,8'd4};
	            din1 <= {8'd5,8'd5,8'd5,8'd5};
		     end
 		383:	 // Writes for 6 and 7 for next macroblock
		      begin
        		  din1 <= {8'd6,8'd6,8'd6,8'd6};
	            din2 <= {8'd7,8'd7,8'd7,8'd7};
		      end
 		447:	 // Writes for 8 and 9 for next macroblock
		      begin
        		  din1 <= {8'd8,8'd8,8'd8,8'd8};
	            din2 <= {8'd9,8'd9,8'd9,8'd9};
		      end
		default:
		      begin
        		  din1 <= din1;
	            din2 <= din2;
		      end
	     endcase
	   
	 end // if(ena)
  end // always

 	// generate clock
	always #2.5 clk <= ~clk;


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

   // Display changes to the signals
  always @(posedge clk2)
    begin
      if (ena)
      begin
	   if (count == 511)
  	     begin
		  if (dout) // eliminates 0 0 from initialization cycle
		    begin
		      $display("X offset is  %d  Y offset is  %d",  dout[31:16], dout[15:0]);
	           case (curcount)
	             3:  begin
			         $display(" Note this search failed to find the block ");
				    $display(" in the upper right corrner since a log search ");
				    $display(" was used and on the first pass there was a tie");
				    $display(" between the upper left and upper right blocks");
				    $display(" at (8,8) and (24,8) and the first was selected");
				    $display(" then a local minima was found.");
				  end
	             7:  begin
			         $display(" Note this search failed to find the block ");
				    $display(" in the lower left corrner since a log search ");
				    $display(" was used and on the first pass there was a tie ");
				    $display(" between the lower left and lower right blocks ");
				    $display(" at (8,24) and (24,24) and the second was selected");
				    $display(" then a local minima was found.");
				    $display(" ");
				    $display(" ");
				    $display(" ");
				    
				  end
	           endcase
		    end
		end
      end
    end
endmodule

