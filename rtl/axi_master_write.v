module axi_master_write #(
    parameter AXI_ID_WD   = 2,
    parameter AXI_DATA_WD = 32,
    parameter AXI_ADDR_WD = 32,
    parameter AXI_STRB_WD = 4
)(
    input                      M_AXI_ACLK,
    input                      M_AXI_ARESETN,    

    input                      w_cmd_valid,
    input  [AXI_ADDR_WD-1 : 0] w_cmd_addr,
    input  [AXI_ID_WD-1   : 0] w_cmd_id,
    input  [1 : 0]             w_cmd_burst,
    input  [2 : 0]             w_cmd_size,
    input  [AXI_ADDR_WD-1 : 0] w_cmd_len,
    output                     w_cmd_ready,
    output                     w_cmd_abort,

    output [AXI_ADDR_WD-1 : 0] M_AXI_AWADDR,
    output [AXI_ID_WD-1   : 0] M_AXI_AWID,
    output [1 : 0]             M_AXI_AWBURST,
    output [2 : 0]             M_AXI_AWSIZE,
    output [7 : 0]             M_AXI_AWLEN,
    output                     M_AXI_AWVALID,
    input                      M_AXI_AWREADY,

    output [AXI_DATA_WD-1 : 0] M_AXI_WDATA,
    output                     M_AXI_WLAST,
    output [AXI_STRB_WD-1 : 0] M_AXI_WSTRB,
    output                     M_AXI_WVALID,
    input                      M_AXI_WREADY,

    input  [AXI_ID_WD-1   : 0] M_AXI_BID,
    input  [1 : 0]             M_AXI_BRESP,
    input                      M_AXI_BVALID,
    output                     M_AXI_BREADY
);

localparam IW = AXI_ID_WD,
           DW = AXI_DATA_WD,
           AW = AXI_ADDR_WD,
           SW = AXI_STRB_WD;

localparam FIXED     = 2'b00,
           INCREMENT = 2'b01,
           WRAP      = 2'b10;

localparam ADDRLSB           = $clog2(DW) - 3;
localparam T_LGMAXBURST      = $clog2((4096 << 3) / DW);
localparam LGMAXBURST        = (T_LGMAXBURST < 8) ? T_LGMAXBURST : 8;
localparam LGMAX_FIXED_BURST = (T_LGMAXBURST < 4) ? T_LGMAXBURST : 4;
localparam AWT               = AW - ADDRLSB;

// instrumental variable
reg w_busy;
reg w_complete_combo;
reg pre_start;
reg start_burst_combo;
reg phantom_start;

// updata when !w_busy
reg [AW-1  : 0] awaddr;
reg [IW-1  : 0] awid;
reg [AWT-1 : 0] awlent;
reg [1 : 0]     awburst;
reg [2 : 0]     awsize;

reg aw_incr_burst;
reg aw_full_incr_burst;
reg aw_full_fixed_burst;
reg aw_needs_alignment;

// outputs in regs
reg            axi_awvalid;
reg [IW-1 : 0] axi_awid;
reg [AW-1 : 0] axi_awaddr;
reg [1 : 0]    axi_awburst;
reg [7 : 0]    axi_awlen;
reg [2 : 0]    axi_awsize;
reg [DW-1 : 0] axi_wdata;
reg [SW-1 : 0] axi_wstrb;
reg            axi_wlast;
reg            axi_wvalid;
reg            axi_bready;

// updata when phantom_start
reg [AWT-1 : 0] aw_requests_remaining;
reg [AWT-1 : 0] aw_next_remaining_combo;

reg aw_next_full_incr_burst_remaining_combo;
reg aw_none_incr_burst_remaining;
reg aw_none_incr_burst_remaining_combo;
reg aw_next_full_fixed_burst_remaining_combo;
reg aw_none_fixed_burst_remaining;
reg aw_none_fixed_burst_remaining_combo;

// first burst
reg [LGMAXBURST-1 : 0] addr_align_combo;
reg [LGMAXBURST   : 0] initial_burst_len_combo;

reg [LGMAXBURST   : 0] wr_max_burst;
reg [LGMAXBURST   : 0] wr_beats_cnt;

// error
reg axi_abort_pending;

wire w_fire     = w_cmd_valid   && w_cmd_ready;
wire awfire     = M_AXI_AWVALID && M_AXI_AWREADY;
wire wfire      = M_AXI_WVALID  && M_AXI_WREADY;
wire bfire      = M_AXI_BVALID  && M_AXI_BREADY;
wire last_wfire = M_AXI_WLAST   && wfire;
wire aw_pending = M_AXI_AWVALID && !M_AXI_AWREADY;
wire w_pending  = M_AXI_WVALID  && !M_AXI_WREADY;

// w_busy
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        w_busy <= 1'b0;
    end
    else if (w_fire) begin
        w_busy <= 1'b1;
    end
    else if (w_complete_combo) begin
        w_busy <= 1'b0;
    end
end

// pre_start
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        pre_start <= 1'b1;
    end
    else begin
        pre_start <= 1'b0;
    end
end

// start_burst_combo
always @(*) begin
    start_burst_combo = !(aw_incr_burst ? aw_none_incr_burst_remaining : aw_none_fixed_burst_remaining);
    if (!w_busy || axi_abort_pending) begin
        start_burst_combo = 1'b0;
    end
    if (axi_awvalid || pre_start) begin
        start_burst_combo = 1'b0;
    end
    if (!last_wfire) begin
        start_burst_combo = 1'b0;
    end
end

// phantom_start
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        phantom_start <= 1'b0;
    end
    else begin
        phantom_start <= start_burst_combo;
    end
end

// axi_awvalid
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_awvalid <= 1'b0;
    end
    else if (!ar_pending) begin
        axi_awvalid <= start_burst_combo;
    end
end

// w_complete_combo
always @(*) begin
    if (!w_busy) begin
        w_complete_combo = 1'b0;
    end
    else begin
        w_complete_combo = last_wfire && (aw_incr_burst ? aw_none_incr_burst_remaining : aw_none_fixed_burst_remaining);
    end
end

// axi_abort_pending
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        axi_abort_pending <= 1'b0;
    end
    else if (bfire && M_AXI_BRESP[1]) begin
        axi_abort_pending <= 1'b1;
    end
end

// regist data
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        awburst <= INCREMENT;
        awsize  <= 'b0;
        awlent  <= 'b0;
        awid    <= 'b0;
        awaddr  <= 'b0;

        aw_incr_burst       <= 1'b1;
        aw_full_incr_burst  <= 1'b0;
        aw_full_fixed_burst <= 1'b0; 
    end
    else if (!w_busy) begin 
        awburst <= w_cmd_burst;
        awsize  <= w_cmd_size;
        awlent  <= w_cmd_len[AW-1 : ADDRLSB];
        awid    <= w_cmd_id;
        awaddr  <= w_cmd_addr;

        aw_incr_burst       <= (w_cmd_burst == INCREMENT);
        aw_full_incr_burst  <= |w_cmd_len[AW-1 : (ADDRLSB+LGMAXBURST)];
        aw_full_fixed_burst <= |w_cmd_len[AW-1 : (ADDRLSB+LGMAX_FIXED_BURST)];
    end
end

// axi_awburst, axi_awid, axi_awsize
always @(posedge M_AXI_ACLK) begin
    if (!aw_pending) begin
        axi_awburst <= awburst;
        axi_awid    <= awid;
        axi_awsize  <= awsize;
    end
end

// aw_needs_alignment
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        aw_needs_alignment <= 1'b0;
        if (|w_cmd_addr[(ADDRLSB+LGMAXBURST-1) : ADDRLSB]) begin
            if (|w_cmd_len[AW-1 : (LGMAXBURST+ADDRLSB)]) begin
                aw_needs_alignment <= 1'b1;
            end
            else if (|(w_cmd_addr[ADDRLSB + : LGMAXBURST] + w_cmd_len[ADDRLSB + : LGMAXBURST])) begin
                aw_needs_alignment <= 1'b1;
            end
        end
    end
end

// initial_burst_len_combo
always @(*) begin
    // awaddr[ADDRLSB + : LGMAXBURST] + (1 + ~awaddr[ADDRLSB + : LGMAXBURST]) = 'b0; 
    addr_align_combo        = 1'b1 + (~awaddr[ADDRLSB + : LGMAXBURST]);
    initial_burst_len_combo = (1 << LGMAXBURST);
    if (!aw_incr_burst) begin
        initial_burst_len_combo = (1 << LGMAX_FIXED_BURST);
        if (!aw_full_fixed_burst) begin
            initial_burst_len_combo = {1'b0, awlent[LGMAXBURST-1 : 0]};
        end
    end
    else if (aw_needs_alignment) begin
        initial_burst_len_combo = {1'b0, addr_align_combo};
    end
    else if (!aw_full_incr_burst) begin
        initial_burst_len_combo = {1'b0, awlent[LGMAXBURST-1 : 0]};
    end
end

// wr_max_burst
always @(posedge M_AXI_ACLK) begin
    if (pre_start) begin
        wr_max_burst <= initial_burst_len_combo;
    end
    else if (phantom_start) begin
        if (ar_incr_burst) begin
            if (!aw_next_full_incr_burst_remaining_combo) begin
                wr_max_burst <= {1'b0, aw_next_remaining_combo[7 : 0]};
            end
            else begin
                wr_max_burst <= (1 << LGMAXBURST);
            end
        end
    end
    else begin
        if (!aw_next_full_fixed_burst_remaining_combo) begin
            wr_max_burst <= {4'b0, aw_next_remaining_combo[3 : 0]};
        end
        else begin
            wr_max_burst <= (1 << LGMAX_FIXED_BURST);
        end
    end
end

always @(posedge M_AXI_ACLK) begin
    if (!ar_pending) begin
        axi_awlen <= wr_max_burst - 1'b1;
    end
end

// updata when phantom_start
always @(posedge M_AXI_ACLK) begin
    if (pre_start) begin
        aw_requests_remaining         <= awlent;
        aw_none_incr_burst_remaining  <= 1'b0;
        aw_none_fixed_burst_remaining <= 1'b0;
    end
    else if (phantom_start) begin
        aw_requests_remaining         <= aw_next_remaining_combo;
        aw_none_incr_burst_remaining  <= aw_none_incr_burst_remaining_combo;
        aw_none_fixed_burst_remaining <= aw_none_fixed_burst_remaining_combo;
    end
    else if (axi_abort_pending) begin
        aw_requests_remaining         <= 'b0;
        aw_none_incr_burst_remaining  <= 1'b1;
        aw_none_fixed_burst_remaining <= 1'b1;
    end
end

always @(*) begin
    // aw_requests_remaining - (M_AXI_ARLEN + 1)
    aw_next_remaining_combo                  = aw_requests_remaining - ({(LGMAXBURST+1){phantom_start}} & wr_max_burst);
    aw_next_full_incr_burst_remaining_combo  = |aw_next_remaining_combo[AWT-1 : LGMAXBURST];
    aw_next_full_fixed_burst_remaining_combo = |aw_next_remaining_combo[AWT-1 : LGMAX_FIXED_BURST];
    aw_none_incr_burst_remaining_combo       = !aw_next_full_incr_burst_remaining_combo && !(|aw_next_remaining_combo[LGMAXBURST-1 : 0]);
    aw_none_fixed_burst_remaining_combo      = !aw_next_full_fixed_burst_remaining_combo && !(|aw_next_remaining_combo[LGMAX_FIXED_BURST-1 : 0]);
end

// axi_awaddr
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        axi_awaddr <= awaddr;
    end
    else if (awfire) begin
        axi_awaddr[ADDRLSB-1 : 0] <= 'b0;
        if (ar_incr_burst) begin
            axi_awaddr[AW-1 : ADDRLSB] <=axi_awaddr[AW-1 : ADDRLSB] + wr_max_burst; 
        end
    end
end

// axi_wvalid
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_wvalid <= 1'b0;
    end
    else if (!w_pending) begin
        if (last_wfire) begin
            axi_wvalid <= 1'b0;
        end
        if (start_burst_combo) begin
            axi_wvalid <= 1'b1;
        end
    end
end

// wr_beats_cnt
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        wr_beats_cnt  <= 'b0;
        wr_none_beats <= 1'b1;
    end
    else begin
        case ({phantom_start,  wfire})
            2'b00: begin end
            2'b01: begin
                wr_beats_cnt  <= wr_beats_cnt - 1'b1;
            end
            2'b10: begin
                wr_beats_cnt  <= wr_beats_cnt + wr_max_burst;
            end
            2'b11: begin
                wr_beats_cnt  <= wr_beats_cnt + M_AXI_AWLEN;
            end
        endcase
    end
end

// axi_wdata
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_wdata <= 'b0;
    end
    else if (wfire) begin
        axi_wdata <= axi_wdata + 1'b1;
        if (M_AXI_WLAST) begin
            axi_wdata <= 'b0;
        end
    end
end

// axi_wlast
always @(posedge M_AXI_ACLK) begin
    if (!w_busy) begin
        axi_wlast <= (awlent == 'b1);
    end
    else if (!w_pending) begin
        if (start_burst_combo) begin
            axi_wlast <= (wr_max_burst == 'b1);
        end
        else if (phantom_start) begin
            axi_wlast <= (M_AXI_AWLEN == 'b1);
        end
        else begin
            axi_wlast <= (wr_beats_cnt == 2);
        end
    end
end

// axi_wstrb
always @(posedge M_AXI_ACLK) begin
    if (!w_pending) begin
        axi_wstrb <= axi_abort_pending ? 'b0 : {SW{1'b1}};
    end
end 

// axi_bready
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_bready <= 1'b0;
    end 
    else if (last_wfire) begin
        axi_bready <= 1'b1;
    end
    else if (bfire) begin
        axi_bready <= 1'b0;
    end
end

assign w_cmd_ready   = !w_busy && !axi_abort_pending;
assign w_cmd_abort   = axi_abort_pending;

assign M_AXI_AWVALID = axi_awvalid;
assign M_AXI_AWADDR  = axi_awaddr;
assign M_AXI_AWID    = axi_awid;
assign M_AXI_AWBURST = axi_awburst;
assign M_AXI_AWSIZE  = axi_awsize;
assign M_AXI_AWLEN   = axi_awlen;

assign M_AXI_WVALID  = axi_wvalid;
assign M_AXI_WDATA   = axi_wdata;
assign M_AXI_WSTRB   = axi_wstrb;
assign M_AXI_WLAST   = axi_wlast;

assign M_AXI_BREADY  = axi_bready;

endmodule