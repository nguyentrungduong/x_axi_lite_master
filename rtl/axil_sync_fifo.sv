////////////////////////////////////////////////////////////////////////////////
// Company     :
//
// Filename    : axil_sync_fifo.sv
// Description : This is synchronous FIFO design with depth is 2**N.
//
// Author      : Duong Nguyen
// Sogan       : "keep it simple"
// History     :
//
////////////////////////////////////////////////////////////////////////////////
module e200g_pcsl_am_sync_fifo
  #(parameter AW    = 3,
    parameter DW    = 32,
    parameter DEPTH = 2**AW,
    parameter HT    = 2)//High threshold
  (
   input logic           rstn,
   input logic           flush_i,

   // write
   input  logic          wclk,
   input  logic          wfifo_i,
   input  logic [DW-1:0] wdata_i,
   output logic          wfull_o,
   output logic          wafull_o,//almost full flag
   output logic [AW:0]   len_o,

   // read
   input  logic          rclk,
   input  logic          rfifo_i,
   output logic          rempty_o,
   output logic [DW-1:0] rdata_o
   );
//------------------------------------------------------------------------------
//Local parameter


//------------------------------------------------------------------------------
//internal signal
logic [AW:0]             nxt_rptr;
logic [AW:0]             rptr;
logic [AW:0]             nxt_wptr;
logic [AW:0]             wptr;

logic                    ren;
logic                    wen;
logic [AW-1:0]           waddr;
logic [AW-1:0]           raddr;



//------------------------------------------------------------------------------
//Read control

assign ren      = rfifo_i;
assign nxt_rptr = flush_i ? '0 :
                  ren     ? (rptr + 1'b1) : rptr;

axil_ffr #(AW+1) ff_rptr(.clk(rclk),.rstn(rstn),.D(nxt_rptr),.Q(rptr));

assign raddr = rptr[AW-1:0];

//Empty detection
assign rempty_o = (nxt_rptr == wptr);

//------------------------------------------------------------------------------
//Write control

assign wen      = wfifo_i;
assign nxt_wptr = flush_i ? '0 :
                  wen     ? (wptr + 1'b1) : wptr;

axil_ffr #(AW+1) ff_wptr(.clk(wclk),.rstn(rstn),.D(nxt_wptr),.Q(wptr));

assign waddr = wptr[AW-1:0];

//Full detection
assign wfull_o = ({~wptr[AW],wptr[AW-1:0]} == rptr);

//------------------------------------------------------------------------------
//FIFO len

assign len_o = wptr - rptr;

//Almost full
assign wafull_o = len_o > HT;

//------------------------------------------------------------------------------
//SRAM or REGFILE

axil_regfile
  #(.REG_DW(DW),
    .REG_AW(AW),
    .DEPTH(DEPTH))  axil_regfile_00
  (
  .clk    (wclk),
  //Write
  .wen_i  (wen),
  .waddr_i(waddr),
  .wdata_i(wdata_i),
  //Read
  .raddr_i(raddr),
  .rdata_o(rdata_o)
  );



endmodule
