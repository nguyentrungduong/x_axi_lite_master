////////////////////////////////////////////////////////////////////////////////
// Company     : 
//
// Filename    : axil_ffre.sv
// Description : D flip flop with asynchronous active low reset signal and
//               Enable control signal
//
// Author      : Duong Nguyen
// Created On  : 
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module axil_ffre
    (
    clk,
    rstn,
    E,
    D,
    Q
    );

//------------------------------------------------------------------------------
//Parameters
parameter DW     = 1'b1;
parameter RST_VL = {DW{1'b0}};
//------------------------------------------------------------------------------
// Port declarations
input  logic              clk;
input  logic              rstn;
input  logic              E;
input  logic [DW-1:0]	  D;
output logic [DW-1:0]	  Q;
//------------------------------------------------------------------------------
//internal signal

//------------------------------------------------------------------------------
// FF
always @ (posedge clk or negedge rstn)
    begin
    if(!rstn) Q <= RST_VL;
    else      Q <= E ? D : Q;
    end

endmodule 

