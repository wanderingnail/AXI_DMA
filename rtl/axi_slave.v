module axi_slave #(
    parameter AXI_ID_WD   = 2,
    parameter AXI_DATA_WD = 32,
    parameter AXI_ADDR_WD = 32,
    parameter AXI_STRB_WD = 4
)(
    input                      S_AXI_ACLK,
    input                      S_AXI_ARESETN,

    input  [AXI_ADDR_WD-1 : 0] S_AXI_AWADDR,
    input  [AXI_ID_WD-1   : 0] S_AXI_AWID,
    input  [1 : 0]             S_AXI_AWBURST,
    input  [2 : 0]             S_AXI_AWSIZE,
    input  [7 : 0]             S_AXI_AWLEN,
    input                      S_AXI_AWVALID,
    output                     S_AXI_AWREADY,

    input  [AXI_DATA_WD-1 : 0] S_AXI_WDATA,
    input  [AXI_STRB_WD-1 : 0] S_AXI_WSTRB,
    input                      S_AXI_WLAST,
    input                      S_AXI_WVALID,
    output                     S_AXI_WREADY,

    output [AXI_ID_WD-1   : 0] S_AXI_BID,
    output [1 : 0]             S_AXI_BRESP,
    output                     S_AXI_BVALID,
    input                      S_AXI_BREADY,

    input  [AXI_ADDR_WD-1 : 0] S_AXI_ARADDR,
    input  [AXI_ID_WD-1   : 0] S_AXI_ARID,
    input  [1 : 0]             S_AXI_ARBURST,
    input  [2 : 0]             S_AXI_ARSIZE,
    input  [7 : 0]             S_AXI_ARLEN,
    input                      S_AXI_ARVALID,
    output                     S_AXI_ARREADY,

    output [AXI_DATA_WD-1 : 0] S_AXI_RDATA,
    output                     S_AXI_RLAST,
    output [AXI_ID_WD-1   : 0] S_AXI_RID,
    output [1 : 0]             S_AXI_RRESP,
    output                     S_AXI_RVALID,
    input                      S_AXI_RREADY
);

localparam IW = AXI_ID_WD,
           DW = AXI_DATA_WD,
           AW = AXI_ADDR_WD,
           SW = AXI_STRB_WD;

localparam DW_BYTE = DW >> 3;
localparam DEPTH   = 1 << AW;

reg [7 : 0] mem [DEPTH-1 : 0];

// temporary data
reg [AW-1 : 0] awaddr;
reg [IW-1 : 0] awid;
reg [1 : 0]    awburst;
reg [2 : 0]    awsize;
reg [7 : 0]    awlen;

reg [AW-1 : 0] araddr;
reg [IW-1 : 0] arid;
reg [1 : 0]    arburst;
reg [2 : 0]    arsize;
reg [7 : 0]    arlen;

// outputs in regs
reg            axi_awready;
reg            axi_wready;
reg [IW-1 : 0] axi_bid;
reg            axi_bvalid;

reg            axi_arready;
reg            axi_rlast;
reg [IW-1 : 0] axi_rid;
reg            axi_rvalid;

// intermidiate variable
reg         bvalid_r;
reg [7 : 0] cur_rlen;

wire [AW-1 : 0] next_wr_addr;
wire [AW-1 : 0] next_rd_addr;

wire awfire = S_AXI_AWVALID  && S_AXI_AWREADY;
wire wfire  = S_AXI_WVALID   && S_AXI_WREADY;
wire arfire = S_AXI_ARVALID  && S_AXI_ARREADY;
wire rfire  = S_AXI_RVALID   && S_AXI_RREADY;
wire b_pend = S_AXI_BVALID   && !S_AXI_BREADY;
wire r_pend = S_AXI_RVALID   && !S_AXI_RREADY;

/************************** CHANEL OF WRITING***************************/

// regist data
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_AWREADY) begin
        awaddr  <= S_AXI_AWADDR;
        awid    <= S_AXI_AWID;
        awburst <= S_AXI_AWBURST;
        awlen   <= S_AXI_AWLEN;
        awsize  <= S_AXI_AWSIZE;
    end
    else if (wfire) begin
        awaddr <= next_wr_addr;
    end
end

// axi_awready, axi_wready
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axi_awready <= 1'b1;
        axi_wready  <= 1'b0;
    end
    else if (awfire) begin
        axi_awready <= 1'b0;
        axi_wready  <= 1'b1;
    end
    else if (wfire) begin
        axi_awready <= S_AXI_WLAST && !b_pend;
        axi_wready  <= !S_AXI_WLAST;
    end
    else if (!S_AXI_AWREADY) begin
        if (axi_wready) begin
            axi_awready <= 1'b0;
        end
        else if (b_pend) begin
            axi_awready <= 1'b0;
        end
        else begin
            axi_wready  <= 1'b1;
        end
    end
end

// axi_bid
always @(posedge S_AXI_ACLK) begin
    if (!b_pend) begin
        axi_bid <= awid;
    end
end

// axi_bvalid
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axi_bvalid <= 1'b0;
    end
    else if (wfire && S_AXI_WLAST) begin
        axi_bvalid <= 1'b1;
    end
    else if (S_AXI_BREADY) begin
        axi_bvalid <= bvalid_r;
    end
end

always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        bvalid_r <= 1'b0;
    end
    else if (b_pend && wfire && S_AXI_WLAST) begin
        bvalid_r <= 1'b1;
    end
    else if (S_AXI_BREADY) begin
        bvalid_r <= 1'b0;
    end
end

// write memory
always @(posedge S_AXI_ACLK) begin
    if (wfire) begin
        for (inter i = 0; i < DW_BYTE; i = i + 1) begin
            mem[awaddr + i] <= S_AXI_WDATA[(idx << 3) +: 8];
        end
    end
end

axi_addr #( 
    .AW(AW),
    .DW(DW)
) get_next_wr_addr(
    .i_last_addr(awaddr),
    .i_burst(awburst),
    .i_size(awsize),
    .i_len(awlen),
    .o_next_addr(next_wr_addr)
);

assign S_AXI_AWREADY = axi_awready;
assign S_AXI_WREADY  = axi_wready;
assign S_AXI_BRESP   = 2'b00;
assign S_AXI_BVALID  = axi_bvalid;
assign S_AXI_BID     = axi_bid;

/************************** CHANEL OF READING***************************/

// regist data
always @(posedge S_AXI_ACLK) begin
    if (S_AXI_ARREADY) begin
        araddr  <= S_AXI_ARADDR;
        arid    <= S_AXI_ARID;
        arburst <= S_AXI_ARBURST;
        arlen   <= S_AXI_ARLEN;
        arsize  <= S_AXI_ARSIZE;
    end
    else if (rfire) begin
        araddr <= next_rd_addr;
    end
end

// cur_rlen
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        cur_rlen <= 'b0;
    end
    else if (arfire) begin
        cur_rlen <= S_AXI_ARLEN;
    end
    else if (rfire) begin
        cur_rlen <= cur_rlen - 1'b1;
    end
end

// axi_arready
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axi_arready <= 1'b1;
    end
    else if (arfire) begin
        axi_arready <= 1'b0;
    end
    else if (!r_pend) begin
        axi_arready <= (cur_rlen <= 1);
    end
end

// axi_rvalid
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axi_rvalid <= 1'b0;
    end
    else if (arfire) begin
        axi_rvalid <= 1'b1;
    end
    else if (rfire) begin
        axi_rvalid <= (cur_rlen > 0);
    end
end

// axi_rlast
always @(posedge S_AXI_ACLK) begin
    if (!S_AXI_ARESETN) begin
        axi_rlast <= 1'b0;
    end
    else if (arfire) begin
        axi_rlast <= (S_AXI_ARLEN == 'b0);
    end
    else if (rfire) begin
        axi_rlast <= (cur_rlen == 'b1);
    end
end

// axi_rid
always @(posedge S_AXI_ACLK) begin
    if (!r_pend) begin
        axi_rid <= arid;
    end
end

axi_addr #( 
    .AW(AW),
    .DW(DW)
) get_next_rd_addr(
    .i_last_addr(araddr),
    .i_burst(arburst),
    .i_size(arsize),
    .i_len(arlen),
    .o_next_addr(next_rd_addr)
);

for (integer i = 0; i < DW_BYTE; i = i + 1) begin
    assign S_AXI_RDATA[(i << 3) + : 8] = mem[araddr + i];
end

assign S_AXI_ARREADY = axi_arready;
assign S_AXI_RVALID  = axi_rvalid;
assign S_AXI_RLAST   = axi_rlast;
assign S_AXI_RID     = axi_rid;
assign S_AXI_RRESP   = 2'b00;

endmodule



