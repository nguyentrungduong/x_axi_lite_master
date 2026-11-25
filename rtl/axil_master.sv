////////////////////////////////////////////////////////////////////////////////
// Company     : 
//
// Filename    : axil_master.sv
// Description : AXI4 Lite master
//
// Author      : Duong Nguyen
// Sogan       : "keep it simple"
// History     : Initial 	
//
////////////////////////////////////////////////////////////////////////////////

module axil_master
    #(
      parameter ADDR_W  = 32 ,
      parameter DATA_W  = 32
     )

    (
    input  logic                            axil_clk       ,// AXI4 Lite clock
    input  logic                            axil_rstn      ,// AXI4 Lite async reset 


    //---------------------------------
    //User interface
    output logic                            usr_rd_ack_o  ,//Read channel handshaking
    input  logic                            usr_rd_req_i  ,//Read channel handshaking

    output logic                            usr_wr_ack_o  ,//Write channel handshaking
    input  logic                            usr_wr_req_i  ,//Write channel handshaking

    input  logic [DATA_W/8-1:0]             usr_wstrb_i,//write strobe
    input  logic [DATA_W-1:0]               usr_wdata_i,//write data
    input  logic [ADDR_W-1:0]               usr_addr_i ,//write address
    input  logic [DATA_W-1:0]               usr_rdata_o,//read data
    input  logic                            usr_rvalid_o,//read data


    //---------------------------------
    //AXI4 Lite interface

    //Write address channel
    input  logic                            axil_awready_i,
    output logic [ADDR_W-1:0]               axil_awaddr_o ,
    output logic                            axil_awvalid_o,
    //Write data channel
    input  logic                            axil_wready_i ,
    output logic [DATA_W-1:0]               axil_wdata_o  ,
    output logic                            axil_wvalid_o ,
    //Write response channel
    input  logic [1:0]                      axil_bresp_i  ,
    output logic                            axil_bready_o ,
    input  logic                            axil_bvalid_i ,
    //Read address channel
    input  logic                            axil_arready_i,
    output logic [ADDR_W-1:0]               axil_araddr_o ,
    output logic                            axil_arvalid_o,
    //Read data channel
    output logic                            axil_rready_o ,
    input  logic [DATA_W-1:0]               axil_rdata_i  ,
    input  logic                            axil_rvalid_i ,
    input  logic                            axil_rresp_i  

    );

//------------------------------------------------------------------------------
//Local parameters

localparam  WSTRB_W = DATA_W/8;



//------------------------------------------------------------------------------
//internal signal



logic                                 wrcmd_fifo_wfifo;
logic [ADDR_W+DATA_W+WSTRB_W-1:0]     wrcmd_fifo_wdata;
logic                                 wrcmd_fifo_wafull;

logic                                 wrcmd_fifo_rfifo;
logic [ADDR_W+DATA_W+WSTRB_W-1:0]     wrcmd_fifo_rdata;
logic                                 wrcmd_fifo_rempty;



logic                                 nxt_usr_wr_ack;

//generate variables
genvar v;




logic                                 nxt_usr_rd_ack;

logic                                 rdcmd_fifo_wfifo;
logic [ADDR_W-1:0]                    rdcmd_fifo_wdata;
logic                                 rdcmd_fifo_wafull; 

logic                                 rdcmd_fifo_rfifo;
logic [ADDR_W-1:0]                    rdcmd_fifo_rdata;
logic                                 rdcmd_fifo_rempty;

logic                                 nxt_st_widle;
logic                                 st_widle;
logic                                 widle_to_write;
logic                                 from_widle;
logic                                 to_widle;


logic                                 nxt_st_write;
logic                                 st_write;
logic                                 write_to_widle;
logic                                 from_write;
logic                                 to_write;


logic [ADDR-1:0]                      nxt_awaddr;
logic                                 nxt_awvalid;
logic                                 clr_awvalid;
logic                                 set_awvalid;

logic [DATA_W-1:0]                    nxt_wdata;
logic                                 nxt_wvalid;
logic                                 clr_wvalid;
logic                                 set_wvalid;


logic                                 ridle_to_read;
logic                                 from_ridle;
logic                                 to_ridle;

logic                                 nxt_st_ridle;
logic                                 st_ridle;

logic                                 read_to_ridle;
logic                                 st_read;
logic                                 nxt_st_read;
logic                                 from_read;
logic                                 to_read;

logic [ADDR_W-1:0]                    nxt_araddr;
logic                                 clr_arvalid;
logic                                 set_arvalid;
logic                                 nxt_arvalid;
logic                                 nxt_usr_rvalid;



//------------------------------------------------------------------------------
//User Write channel handshaking



//Write channel ACK
assign nxt_usr_wr_ack = ~wrcmd_fifo_wafull; 


axil_ffr #(1) ffr_wr_ack (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_usr_wr_ack),.Q(usr_wr_ack_o));

//write FIFO
assign wrcmd_fifo_wfifo = usr_wr_ack_o & usr_wr_req_i; 

assign wrcmd_fifo_wdata = {usr_addr_i ,
                           usr_wdata_i,
                           usr_wstrb_i };

//write command FIFO
axil_sync_fifo 
  #(.AW    (2),
    .DW    (ADDR_W+DATA_W+WSTRB_W),//68 bit
    .DEPTH (4),
    .HT    (2) )                              write_cmd_fifo_00
  (
   .rstn    (axil_rstn),
   .flush_i ('0),//this code used for simulation, so no need flushing.

   // write
   .wclk    (axil_clk),
   .wfifo_i (wrcmd_fifo_wfifo),
   .wdata_i (wrcmd_fifo_wdata),
   .wfull_o (),//currently, don't use 
   .wafull_o(wrcmd_fifo_wafull),//this asserted when FIFO level greater than high threshold.
   .len_o   (),//current FIFO len

   // read
   .rclk    (axil_clk),
   .rfifo_i (wrcmd_fifo_rfifo),
   .rempty_o(wrcmd_fifo_rempty),//1: is empty
   .rdata_o (wrcmd_fifo_rdata)
   );


assign wrcmd_fifo_rfifo = widle_to_write; 


//------------------------------------------------------------------------------
//User read channel handshaking



//read channel ACK
assign nxt_usr_rd_ack = ~rdcmd_fifo_wafull; 


axil_ffr #(1) ffr_rd_ack (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_usr_rd_ack),.Q(usr_rd_ack_o));

//write READ CMD FIFO
assign rdcmd_fifo_wfifo = usr_rd_ack_o & usr_rd_req_i; 

assign rdcmd_fifo_wdata = usr_addr_i; //For read command, only need read address.

//write command FIFO
axil_sync_fifo 
  #(.AW    (2),
    .DW    (ADDR_W),//32 bit
    .DEPTH (4),
    .HT    (2) )                              read_cmd_fifo_00
  (
   .rstn    (axil_rstn),
   .flush_i ('0),//this code used for simulation, so no need flushing.

   // write
   .wclk    (axil_clk),
   .wfifo_i (rdcmd_fifo_wfifo),
   .wdata_i (rdcmd_fifo_wdata),
   .wfull_o (),//currently, don't use
   .wafull_o(rdcmd_fifo_wafull),//this asserted when FIFO level greater than high threshold.
   .len_o   (),//current FIFO len

   // read
   .rclk    (axil_clk),
   .rfifo_i (rdcmd_fifo_rfifo),
   .rempty_o(rdcmd_fifo_rempty),
   .rdata_o (rdcmd_fifo_rdata)
   );


assign rdcmd_fifo_rfifo = ridle_to_read; 


//------------------------------------------------------------------------------
//AXI write channels control

//Write IDLE state, go to idle after reset
assign widle_to_write = st_widle & (~wrcmd_fifo_rempty);

assign from_widle = widle_to_write;

assign to_widle   = write_to_widle;

assign nxt_st_widle = to_widle   ? 1'b1 :
                      from_widle ? 1'b0 : st_widle;

axil_ffr #(1,1'b1) ffr_st_widle (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_st_widle),.Q(st_widle));


//WRITE state, write command is processed at this state
assign write_to_widle = st_write & axil_bready_o & axil_bvalid_i;//go to write idle when received axi bresp 

assign from_write = write_to_widle;

assign to_write   = widle_to_write;

assign nxt_st_write = to_write   ? 1'b1 :
                      from_write ? 1'b0 : st_write;

axil_ffr #(1) ffr_st_write (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_st_write),.Q(st_write));




//AXI4 Lite write address channel control
assign nxt_awaddr = wrcmd_fifo_rfifo ? wrcmd_fifo_rdata[(WSTRB_W+DATA_W) +:ADDR_W] : axil_awaddr_o;//32 bit write address

axil_ffr #(ADDR_W) ffr_axil_awaddr (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_awaddr),.Q(axil_awaddr_o));



assign clr_awvalid = st_widle | (axil_awvalid_o & axil_awready_i);
assign set_awvalid = widle_to_write;

assign nxt_awvalid =  clr_awvalid ? '0 :
                      set_awvalid ? '1 : axil_awvalid_o;
                         

axil_ffr #(1) ffr_axil_awvalid (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_awvalid),.Q(axil_awvalid_o));


//AXI4 Lite write data channel control
assign nxt_wdata = wrcmd_fifo_rfifo ? wrcmd_fifo_rdata[WSTRB_W +:DATA_W] : axil_wdata_o;//32 bit write data

axil_ffr #(ADDR_W) ffr_axil_wdata (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_wdata),.Q(axil_wdata_o));


assign clr_valid = st_widle | (axil_wvalid_o & axil_wready_i);
assign set_valid = widle_to_write;

assign nxt_wvalid =  clr_wvalid ? '0 :
                     set_wvalid ? '1 : axil_wvalid_o;
                         

axil_ffr #(1) ffr_axil_wvalid (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_wvalid),.Q(axil_wvalid_o));


//AXI4 Lite write respone channel control, currently don't use axil_bresp_i[1:0] to
//decode status of write transaction.

assign axil_bready_o = '1;//1: mean can received write response any time.




//------------------------------------------------------------------------------
//AXI read channels control


//read IDLE state, go to read idle after reset
assign ridle_to_read = st_ridle & (~rdcmd_fifo_rempty);

assign from_ridle = ridle_to_read;

assign to_ridle   = read_to_ridle;

assign nxt_st_ridle = to_ridle   ? 1'b1 :
                      from_ridle ? 1'b0 : st_ridle;

axil_ffr #(1,1'b1) ffr_st_ridle (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_st_ridle),.Q(st_ridle));


//READ state, read command is processed at this state
assign read_to_ridle = st_read & axil_rvalid_i & axil_rready_o;//go to write idle when received return read data 

assign from_read = read_to_ridle;

assign to_read   = ridle_to_read;

assign nxt_st_read = to_read   ? 1'b1 :
                     from_read ? 1'b0 : st_read;

axil_ffr #(1) ffr_st_read (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_st_read),.Q(st_read));



//AXI4 Lite read address channel control

assign nxt_araddr = rdcmd_fifo_rfifo ? rdcmd_fifo_rdata : axil_awaddr_o;//32 bit read address

axil_ffr #(ADDR_W) ffr_axil_araddr (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_araddr),.Q(axil_araddr_o));



assign clr_arvalid = st_ridle | (axil_arvalid_o & axil_arready_i);
assign set_arvalid = ridle_to_read;

assign nxt_arvalid =  clr_arvalid ? '0 :
                      set_arvalid ? '1 : axil_arvalid_o;
                         

axil_ffr #(1) ffr_axil_arvalid (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_arvalid),.Q(axil_arvalid_o));



//AXI4 Lite read data channel control

assign axil_rready_o = '1; //1 : mean can received returned data any time.



axil_ffr #(DATA_W) ffr_usr_rdata (.clk(axil_clk),.rstn(axil_rstn),.D(axil_rdata_i),.Q(usr_rdata_o));

assign nxt_usr_rvalid = axil_rready_o & axil_rvalid_i;

axil_ffr #(1) ffr_usr_rdata (.clk(axil_clk),.rstn(axil_rstn),.D(nxt_usr_rvalid),.Q(usr_rvalid_o));


endmodule 

