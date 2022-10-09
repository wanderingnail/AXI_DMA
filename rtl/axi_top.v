module axi_top #(
    parameter AXI_ID_WD   = 2,
    parameter AXI_DATA_WD = 32,
    parameter AXI_ADDR_WD = 32,
    parameter AXI_STRB_WD = 4
)(
    input                      AXI_ACLK,
    input                      AXI_ARESETN,    

    input                      cmd_valid,
    input  [AXI_ADDR_WD-1 : 0] cmd_addr,
    input  [AXI_ID_WD-1   : 0] cmd_id,
    input  [1 : 0]             cmd_burst,
    input  [2 : 0]             cmd_size,
    input  [AXI_ADDR_WD-1 : 0] cmd_len,
    output                     cmd_ready,
    output                     cmd_abort
);

wire [AXI_ADDR_WD-1 : 0] AXI_AWADDR;
wire [AXI_ID_WD-1   : 0] AXI_AWID;
wire [1 : 0]             AXI_AWBURST;
wire [2 : 0]             AXI_AWSIZE;
wire [7 : 0]             AXI_AWLEN;
wire                     AXI_AWVALID;
wire                     AXI_AWREADY;

wire [AXI_DATA_WD-1 : 0] AXI_WDATA;
wire [AXI_STRB_WD-1 : 0] AXI_WSTRB;
wire                     AXI_WLAST;
wire                     AXI_WVALID;
wire                     AXI_WREADY;

wire [AXI_ID_WD-1   : 0] AXI_BID;
wire [1 : 0]             AXI_BRESP;
wire                     AXI_BVALID;
wire                     AXI_BREADY;

wire [AXI_ADDR_WD-1 : 0] AXI_ARADDR;
wire [AXI_ID_WD-1   : 0] AXI_ARID;
wire [1 : 0]             AXI_ARBURST;
wire [2 : 0]             AXI_ARSIZE;
wire [7 : 0]             AXI_ARLEN;
wire                     AXI_ARVALID;
wire                     AXI_ARREADY;

wire [AXI_DATA_WD-1 : 0] AXI_RDATA;
wire                     AXI_RLAST;
wire [AXI_ID_WD-1   : 0] AXI_RID;
wire [1 : 0]             AXI_RRESP;
wire                     AXI_RVALID;
wire                     AXI_RREADY;

axi_master_write #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) axi_master_write(
    .M_AXI_ACLK(AXI_ACLK),
    .M_AXI_ARESETN(AXI_ARESETN),    
    .w_cmd_valid(cmd_valid),
    .w_cmd_addr(cmd_addr),
    .w_cmd_id(cmd_id),
    .w_cmd_burst(cmd_burst),
    .w_cmd_size(cmd_size),
    .w_cmd_len(cmd_len),
    .w_cmd_ready(cmd_ready),
    .w_cmd_abort(cmd_abort),
    .M_AXI_AWADDR(AXI_AWADDR),
    .M_AXI_AWID(AXI_AWID),
    .M_AXI_AWBURST(AXI_AWBURST),
    .M_AXI_AWSIZE(AXI_AWSIZE),
    .M_AXI_AWLEN(AXI_AWLEN),
    .M_AXI_AWVALID(AXI_AWVALID),
    .M_AXI_AWREADY(AXI_AWREADY),
    .M_AXI_WDATA(AXI_WDATA),
    .M_AXI_WLAST(AXI_WLAST),
    .M_AXI_WSTRB(AXI_WSTRB),
    .M_AXI_WVALID(AXI_WVALID),
    .M_AXI_WREADY(AXI_WREADY),
    .M_AXI_BID(AXI_BID),
    .M_AXI_BRESP(AXI_BRESP),
    .M_AXI_BVALID(AXI_BVALID),
    .M_AXI_BREADY(AXI_BREADY)
);

axi_master_read #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) axi_master_read(
    .M_AXI_ACLK(AXI_ACLK),
    .M_AXI_ARESETN(AXI_ARESETN),    
    .r_cmd_valid(cmd_valid),
    .r_cmd_addr(cmd_addr),
    .r_cmd_id(cmd_id),
    .r_cmd_burst(cmd_burst),
    .r_cmd_size(cmd_size),
    .r_cmd_len(cmd_len),
    .r_cmd_ready(cmd_ready),
    .r_cmd_abort(cmd_abort),
    .M_AXI_ARADDR(AXI_ARADDR),
    .M_AXI_ARID(AXI_ARID),
    .M_AXI_ARBURST(AXI_ARBURST),
    .M_AXI_ARSIZE(AXI_ARSIZE),
    .M_AXI_ARLEN(AXI_ARLEN),
    .M_AXI_ARVALID(AXI_ARVALID),
    .M_AXI_ARREADY(AXI_ARREADY),
    .M_AXI_RDATA(AXI_RDATA),
    .M_AXI_RLAST(AXI_RLAST),
    .M_AXI_RVALID(AXI_RVALID),
    .M_AXI_RREADY(AXI_RREADY),
    .M_AXI_RID(AXI_RID),
    .M_AXI_RRESP(AXI_RRESP)
);

axi_slave #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) axi_slave(
    .S_AXI_ACLK(AXI_ACLK),
    .S_AXI_ARESETN(AXI_ARESETN),    
    .S_AXI_AWADDR(AXI_AWADDR),
    .S_AXI_AWID(AXI_AWID),
    .S_AXI_AWBURST(AXI_AWBURST),
    .S_AXI_AWSIZE(AXI_AWSIZE),
    .S_AXI_AWLEN(AXI_AWLEN),
    .S_AXI_AWVALID(AXI_AWVALID),
    .S_AXI_AWREADY(AXI_AWREADY),
    .S_AXI_WDATA(AXI_WDATA),
    .S_AXI_WLAST(AXI_WLAST),
    .S_AXI_WSTRB(AXI_WSTRB),
    .S_AXI_WVALID(AXI_WVALID),
    .S_AXI_WREADY(AXI_WREADY),
    .S_AXI_BID(AXI_BID),
    .S_AXI_BRESP(AXI_BRESP),
    .S_AXI_BVALID(AXI_BVALID),
    .S_AXI_BREADY(AXI_BREADY),
    .S_AXI_ARADDR(AXI_ARADDR),
    .S_AXI_ARID(AXI_ARID),
    .S_AXI_ARBURST(AXI_ARBURST),
    .S_AXI_ARSIZE(AXI_ARSIZE),
    .S_AXI_ARLEN(AXI_ARLEN),
    .S_AXI_ARVALID(AXI_ARVALID),
    .S_AXI_ARREADY(AXI_ARREADY),
    .S_AXI_RDATA(AXI_RDATA),
    .S_AXI_RLAST(AXI_RLAST),
    .S_AXI_RVALID(AXI_RVALID),
    .S_AXI_RREADY(AXI_RREADY),
    .S_AXI_RID(AXI_RID),
    .S_AXI_RRESP(AXI_RRESP)
);

endmodule