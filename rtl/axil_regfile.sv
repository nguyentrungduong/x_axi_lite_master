
////////////////////////////////////////////////////////////////////////////////
// Company     :
//
// Filename    : axil_regfile.sv
// Description : register file. There are no read enable signal, read data is
//               return immediately when read address change.  
//
// Author      : 
// Created On  : 
// History     : 
//
////////////////////////////////////////////////////////////////////////////////
module axil_regfile
  #(parameter REG_DW = 32,
    parameter REG_AW = 3,
    parameter DEPTH  = 2**REG_AW)
  (
  input  logic                clk,
  //Write
  input  logic                wen_i,
  input  logic [REG_AW-1:0]   waddr_i,
  input  logic [REG_DW-1:0]   wdata_i,
  //Read
  input  logic [REG_AW-1:0]   raddr_i,
  output logic [REG_DW-1:0]   rdata_o
  );

//------------------------------------------------------------------------------
//parameters

//------------------------------------------------------------------------------
//internal signal
logic  [DEPTH-1:0][REG_DW-1:0] regfile;


//Generate variables
genvar k;

generate
  for (k = 0; k < DEPTH; k++)
    begin : REG_GEN
    always_ff @(posedge clk) regfile[k] <= (wen_i & (waddr_i == REG_AW'(k))) ? wdata_i : regfile[k]; 
    end
endgenerate

//Read output

assign rdata_o = regfile[raddr_i]; 



endmodule
