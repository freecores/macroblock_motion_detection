///////////////////////////////////////////////////////////////////////////
// Function : Synchronous read write RAM                                 //
// Coder : Deepak Kumar Tala                                             //
// Date : 18-April-2002                                                  //
///////////////////////////////////////////////////////////////////////////
//														   //
//  Synchronous read write RAM from www.asic-world.com 			   //
//														   //
//  The following disclaimer from website applies to this code:		   //
//														   //
//  I don't makes any claims, promises or guarantees about the           //
//  accuracy, completeness, or adequacy of the contents of this 		   //
//  website and expressly disclaims liability for errors and             //
//  omissions in the contents of this website. No warranty of		   //
//  any kind, implied, expressed or statutory, including but not	        //
//  limited to the warranties of non-infringement of third	             //
//  party rights, title, merchantability, fitness for a particular	   //
//  purpose and freedom from computer virus, is given with respect	   //
//  to the contents of this website or its hyperlinks to other           //
//  Internet resources. Reference in this website to any specific 	   //
//  commercial products, processes, or services, or the use of 	        //
//  any trade, firm or corporation name is for the information, and	   //
//  does not constitute endorsement, recommendation, or favoring by	   //
//  me. All the source code and Tutorials are to be used on your own     //
//  risk. All the ideas and views in this site are my own and are	   //
//  not by any means related to my employer.					        //
//														   //
///////////////////////////////////////////////////////////////////////////
//														   //
//  Bus width adjusted for use with Motion Detection Core and timescale  //
//  directive added for simulation.           					   //
//														   //
///////////////////////////////////////////////////////////////////////////

//synopsys translate_off
`include "timescale.v"
//synopsys translate_on
module ram_dp_sr_sw ( 

clk             , // Clock Input 
address_0 , // address_0 Input
data_0      , // data_0 bi-directional
cs_0          , // Chip Select
we_0         , // Write Enable/Read Enable
oe_0          , // Output Enable 
address_1 , // address_1 Input
data_1       , // data_1 bi-directional
cs_1           , // Chip Select
we_1          , // Write Enable/Read Enable
oe_1            // Output Enable
); 

parameter data_0_WIDTH = 32 ;
parameter ADDR_WIDTH = 17 ;
parameter RAM_DEPTH = 1 << ADDR_WIDTH;

//--------------Input Ports----------------------- 
input clk;
input [ADDR_WIDTH-1:0] address_0 ;
input cs_0 ;
input we_0 ;
input oe_0 ; 
input [ADDR_WIDTH-1:0] address_1 ;
input cs_1 ;
input we_1 ;
input oe_1 ; 

//--------------Inout Ports----------------------- 
inout [data_0_WIDTH-1:0] data_0 ; 
inout [data_0_WIDTH-1:0] data_1 ;

//--------------Internal variables---------------- 
reg [data_0_WIDTH-1:0] data_0_out ; 
reg [data_0_WIDTH-1:0] data_1_out ;
reg [data_0_WIDTH-1:0] mem [0:RAM_DEPTH-1];

//--------------Code Starts Here------------------ 
// Memory Write Block 
// Write Operation : When we_0 = 1, cs_0 = 1
always @ (posedge clk)
begin : MEM_WRITE
if ( cs_0 && we_0 )
   mem[address_0] <= data_0;
if (cs_1 && we_1)
   mem[address_1] <= data_1;
end 

  

// Tri-State Buffer control 
// output : When we_0 = 0, oe_0 = 1, cs_0 = 1
assign data_0 = (cs_0 && oe_0 && !we_0) ? data_0_out : 32'bz; 

// Memory Read Block 
// Read Operation : When we_0 = 0, oe_0 = 1, cs_0 = 1
always @ (posedge clk)
begin : MEM_READ_0
if (cs_0 && !we_0 && oe_0)
  data_0_out <= mem[address_0]; 
else 
  data_0_out <= 0; 
end 

//Second Port of RAM
// Tri-State Buffer control 
// output : When we_0 = 0, oe_0 = 1, cs_0 = 1
assign data_1 = (cs_1 && oe_1 && !we_1) ? data_1_out : 32'bz; 
// Memory Read Block 1 
// Read Operation : When we_1 = 0, oe_1 = 1, cs_1 = 1
always @ (posedge clk)
begin : MEM_READ_1
if (cs_1 && !we_1 && oe_1)
  data_1_out <= mem[address_1]; 
else 
  data_1_out <= 0; 
end

endmodule // End of Module ram_dp_sr_sw 
