module DMAC #(
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
    output                     cmd_abort,

    output [AXI_ADDR_WD-1 : 0] AXI_AWADDR,
    output [AXI_ID_WD-1   : 0] AXI_AWID,
    output [1 : 0]             AXI_AWBURST,
    output [2 : 0]             AXI_AWSIZE,
    output [7 : 0]             AXI_AWLEN,
    output                     AXI_AWVALID,
    output                     AXI_AWREADY,

    output [AXI_DATA_WD-1 : 0] AXI_WDATA,
    output [AXI_STRB_WD-1 : 0] AXI_WSTRB,
    output                     AXI_WLAST,
    output                     AXI_WVALID,
    output                     AXI_WREADY,

    output [AXI_ID_WD-1   : 0] AXI_BID,
    output [1 : 0]             AXI_BRESP,
    output                     AXI_BVALID,
    output                     AXI_BREADY,

    output [AXI_ADDR_WD-1 : 0] AXI_ARADDR,
    output [AXI_ID_WD-1   : 0] AXI_ARID,
    output [1 : 0]             AXI_ARBURST,
    output [2 : 0]             AXI_ARSIZE,
    output [7 : 0]             AXI_ARLEN,
    output                     AXI_ARVALID,
    output                     AXI_ARREADY,

    output [AXI_DATA_WD-1 : 0] AXI_RDATA,
    output                     AXI_RLAST,
    output [AXI_ID_WD-1   : 0] AXI_RID,
    output [1 : 0]             AXI_RRESP,
    output                     AXI_RVALID,
    output                     AXI_RREADY
);

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

endmodule