`timescale 1ns / 1ns
module tb_DMAC;

localparam AXI_ID_WD   = 2,
           AXI_DATA_WD = 32,
           AXI_ADDR_WD = 16,
           AXI_STRB_WD = 4;

reg                     clk;
reg                     rst_n;    
reg                     cmd_valid;
reg [AXI_ADDR_WD-1 : 0] cmd_addr;
reg [AXI_ID_WD-1   : 0] cmd_id;
reg [1 : 0]             cmd_burst;
reg [2 : 0]             cmd_size;
reg [AXI_ADDR_WD-1 : 0] cmd_len;
wire                    cmd_ready;
wire                    cmd_abort;

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

initial begin
    $dumpfile("DMAC.vcd");
    $dumpvars;
end

initial begin
    clk = 0;
    forever begin
        #5;
        clk = ~clk;
    end
end

initial begin
    rst_n = 0;
    #7;
    rst_n = 1;
    #11000;
    $finish;
end

initial begin
    cmd_valid = 1'b1;
    cmd_addr  = {{8{1'b0}}, {8{1'b1}}};
    cmd_id    = 'b0;
    cmd_len   = 2080;
    cmd_size  = 3'b010;
    cmd_burst = 2'b01;
    #5500;
    cmd_valid = 1'b1;
end

always @(posedge clk) begin
    if (cmd_valid && cmd_ready) begin
        cmd_valid <= 1'b0;
    end
end

DMAC #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) DMA_CONTROLLER(
    .AXI_ACLK(clk),
    .AXI_ARESETN(rst_n),    
    .cmd_valid(cmd_valid),
    .cmd_addr(cmd_addr),
    .cmd_id(cmd_id),
    .cmd_burst(cmd_burst),
    .cmd_size(cmd_size),
    .cmd_len(cmd_len),
    .cmd_ready(cmd_ready),
    .cmd_abort(cmd_abort),
    .AXI_AWADDR(AXI_AWADDR),
    .AXI_AWID(AXI_AWID),
    .AXI_AWBURST(AXI_AWBURST),
    .AXI_AWSIZE(AXI_AWSIZE),
    .AXI_AWLEN(AXI_AWLEN),
    .AXI_AWVALID(AXI_AWVALID),
    .AXI_AWREADY(AXI_AWREADY),
    .AXI_WDATA(AXI_WDATA),
    .AXI_WLAST(AXI_WLAST),
    .AXI_WSTRB(AXI_WSTRB),
    .AXI_WVALID(AXI_WVALID),
    .AXI_WREADY(AXI_WREADY),
    .AXI_BID(AXI_BID),
    .AXI_BRESP(AXI_BRESP),
    .AXI_BVALID(AXI_BVALID),
    .AXI_BREADY(AXI_BREADY),
    .AXI_ARADDR(AXI_ARADDR),
    .AXI_ARID(AXI_ARID),
    .AXI_ARBURST(AXI_ARBURST),
    .AXI_ARSIZE(AXI_ARSIZE),
    .AXI_ARLEN(AXI_ARLEN),
    .AXI_ARVALID(AXI_ARVALID),
    .AXI_ARREADY(AXI_ARREADY),
    .AXI_RDATA(AXI_RDATA),
    .AXI_RLAST(AXI_RLAST),
    .AXI_RVALID(AXI_RVALID),
    .AXI_RREADY(AXI_RREADY),
    .AXI_RID(AXI_RID),
    .AXI_RRESP(AXI_RRESP)
);

axi_slave_outstanding #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) axi_slave_outstanding(
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rst_n),    
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