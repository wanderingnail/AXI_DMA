module axi_master_read #(
    parameter AXI_ID_WD   = 2,
    parameter AXI_DATA_WD = 32,
    parameter AXI_ADDR_WD = 32,
    parameter AXI_STRB_WD = 4
)(
    input                      M_AXI_ACLK,
    input                      M_AXI_ARESETN,    

    input                      r_cmd_valid,
    input  [AXI_ADDR_WD-1 : 0] r_cmd_addr,
    input  [AXI_ID_WD-1   : 0] r_cmd_id,
    input  [1 : 0]             r_cmd_burst,
    input  [2 : 0]             r_cmd_size,
    input  [AXI_ADDR_WD-1 : 0] r_cmd_len,
    output                     r_cmd_ready,
    output                     r_cmd_abort,

    output [AXI_ADDR_WD-1 : 0] M_AXI_ARADDR,
    output [AXI_ID_WD-1   : 0] M_AXI_ARID,
    output [1 : 0]             M_AXI_ARBURST,
    output [2 : 0]             M_AXI_ARSIZE,
    output [7 : 0]             M_AXI_ARLEN,
    output                     M_AXI_ARVALID,
    input                      M_AXI_ARREADY,

    input  [AXI_DATA_WD-1 : 0] M_AXI_RDATA,
    input                      M_AXI_RLAST,
    input  [AXI_ID_WD-1   : 0] M_AXI_RID,
    input  [1 : 0]             M_AXI_RRESP,
    input                      M_AXI_RVALID,
    output                     M_AXI_RREADY
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
reg r_busy;
reg r_complete_combo;
reg pre_start;
reg start_burst_combo;
reg phantom_start;

// updata when !r_busy
reg [AW-1  : 0] araddr;
reg [IW-1  : 0] arid;
reg [AWT-1 : 0] arlent;
reg [1 : 0]     arburst;
reg [2 : 0]     arsize;

reg ar_incr_burst;
reg ar_full_incr_burst;
reg ar_full_fixed_burst;
reg ar_needs_alignment;

// outputs in regs
reg            axi_arvalid;
reg [IW-1 : 0] axi_arid;
reg [AW-1 : 0] axi_araddr;
reg [1 : 0]    axi_arburst;
reg [7 : 0]    axi_arlen;
reg [2 : 0]    axi_arsize;
reg            axi_rready;

// updata when phantom_start
reg [AWT-1 : 0] ar_requests_remaining;
reg [AWT-1 : 0] ar_next_remaining_combo;

reg ar_next_full_incr_burst_remaining_combo;
reg ar_none_incr_burst_remaining;
reg ar_none_incr_burst_remaining_combo;
reg ar_next_full_fixed_burst_remaining_combo;
reg ar_none_fixed_burst_remaining;
reg ar_none_fixed_burst_remaining_combo;

// first burst
reg [LGMAXBURST-1 : 0] addr_align_combo;
reg [LGMAXBURST   : 0] initial_burst_len_combo;
reg [LGMAXBURST   : 0] rd_max_burst;

// outstaning
reg [9 : 0] ar_burst_outstanding;
reg         ar_last_outstanding;

// error
reg axi_abort_pending;

wire r_fire     = r_cmd_valid   && r_cmd_ready;
wire arfire     = M_AXI_ARVALID && M_AXI_ARREADY;
wire rfire      = M_AXI_RVALID  && M_AXI_RREADY;
wire last_rfire = M_AXI_RLAST   && rfire;
wire ar_pending = M_AXI_ARVALID && !M_AXI_ARREADY;

// r_busy
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        r_busy <= 1'b0;
    end
    else if (r_fire) begin
        r_busy <= 1'b1;
    end
    else if (r_complete_combo) begin
        r_busy <= 1'b0;
    end
end

// pre_start
always @(posedge M_AXI_ACLK) begin
    if (!r_busy) begin
        pre_start <= 1'b1;
    end
    else begin
        pre_start <= 1'b0;
    end
end

// start_burst_combo
always @(*) begin
    start_burst_combo = !(ar_incr_burst ? ar_none_incr_burst_remaining : ar_none_fixed_burst_remaining);
    if (!r_busy || axi_abort_pending) begin
        start_burst_combo = 1'b0;
    end
    if (axi_arvalid || pre_start) begin
        start_burst_combo = 1'b0;
    end
end

// phantom_start
always @(posedge M_AXI_ACLK) begin
    if (!r_busy) begin
        phantom_start <= 1'b0;
    end
    else begin
        phantom_start <= start_burst_combo;
    end
end

// axi_arvalid
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_arvalid <= 1'b0;
    end
    else if (!ar_pending) begin
        axi_arvalid <= start_burst_combo;
    end
end

// r_complete_combo
always @(*) begin
    if (!r_busy) begin
        r_complete_combo = 1'b0;
    end
    else begin
        r_complete_combo = last_rfire && ar_last_outstanding;
    end
end

// outstanding
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        ar_burst_outstanding <= 'b0;
        ar_last_outstanding  <= 1'b0;
    end
    else begin
        if (phantom_start) begin
            ar_burst_outstanding <= ar_burst_outstanding + 1'b1;
            ar_last_outstanding  <= (ar_burst_outstanding == 1'b0);
        end
        if (last_rfire) begin
            ar_burst_outstanding <= ar_burst_outstanding - 1'b1;
            ar_last_outstanding  <= (ar_burst_outstanding == 'd2);
        end
    end
end

// axi_abort_pending
always @(posedge M_AXI_ACLK) begin
    if (!r_busy) begin
        axi_abort_pending <= 1'b0;
    end
    else if (rfire && M_AXI_RRESP[1]) begin
        axi_abort_pending <= 1'b1;
    end
end

// regist data
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        arburst <= INCREMENT;
        arsize  <= 'b0;
        arlent  <= 'b0;
        arid    <= 'b0;
        araddr  <= 'b0;

        ar_incr_burst       <= 1'b1;
        ar_full_incr_burst  <= 1'b0;
        ar_full_fixed_burst <= 1'b0; 
    end
    else if (!r_busy) begin 
        arburst <= r_cmd_burst;
        arsize  <= r_cmd_size;
        arlent  <= r_cmd_len[ADDRLSB + : AWT];
        arid    <= r_cmd_id;
        araddr  <= r_cmd_addr;

        ar_incr_burst       <= (r_cmd_burst == INCREMENT);
        ar_full_incr_burst  <= |r_cmd_len[AW-1 : (ADDRLSB+LGMAXBURST)];
        ar_full_fixed_burst <= |r_cmd_len[AW-1 : (ADDRLSB+LGMAX_FIXED_BURST)];
    end
end

// axi_arburst, axi_arid, axi_arsize
always @(posedge M_AXI_ACLK) begin
    if (!ar_pending) begin
        axi_arburst <= arburst;
        axi_arid    <= arid;
        axi_arsize  <= arsize;
    end
end

// ar_needs_alignmeng
always @(posedge M_AXI_ACLK) begin
    if (!r_busy) begin
        ar_needs_alignment <= 1'b0;
        if (|r_cmd_addr[ADDRLSB + : LGMAXBURST]) begin
            if (|r_cmd_len[AW-1 : (LGMAXBURST+ADDRLSB)]) begin
                ar_needs_alignment <= 1'b1;
            end
            else if (|(r_cmd_addr[ADDRLSB + : LGMAXBURST] + r_cmd_len[ADDRLSB + : LGMAXBURST])) begin
                ar_needs_alignment <= 1'b1;
            end
        end
    end
end

// initial_burst_len_combo
always @(*) begin
    // araddr[ADDRLSB + : LGMAXBURST] + (1 + ~araddr[ADDRLSB + : LGMAXBURST]) = 'b0; 
    addr_align_combo        = 1'b1 + (~araddr[ADDRLSB + : LGMAXBURST]);
    initial_burst_len_combo = (1 << LGMAXBURST);
    if (!ar_incr_burst) begin
        initial_burst_len_combo = (1 << LGMAX_FIXED_BURST);
        if (!ar_full_fixed_burst) begin
            initial_burst_len_combo = {1'b0, arlent[LGMAXBURST-1 : 0]};
        end
    end
    else if (ar_needs_alignment) begin
        initial_burst_len_combo = {1'b0, addr_align_combo};
    end
    else if (!ar_full_incr_burst) begin
        initial_burst_len_combo = {1'b0, arlent[LGMAXBURST-1 : 0]};
    end
end

// rd_max_burst
always @(posedge M_AXI_ACLK) begin
    if (pre_start) begin
        rd_max_burst <= initial_burst_len_combo;
    end
    else if (phantom_start) begin
        if (ar_incr_burst) begin
            if (!ar_next_full_incr_burst_remaining_combo) begin
                rd_max_burst <= {1'b0, ar_next_remaining_combo[7 : 0]};
            end
            else begin
                rd_max_burst <= (1 << LGMAXBURST);
            end
        end
    end
    else begin
        if (!ar_next_full_fixed_burst_remaining_combo) begin
            rd_max_burst <= {4'b0, ar_next_remaining_combo[3 : 0]};
        end
        else begin
            rd_max_burst <= (1 << LGMAX_FIXED_BURST);
        end
    end
end

always @(posedge M_AXI_ACLK) begin
    if (!ar_pending) begin
        axi_arlen <= rd_max_burst - 1'b1;
    end
end

// updata when phantom_start
always @(posedge M_AXI_ACLK) begin
    if (pre_start) begin
        ar_requests_remaining         <= arlent;
        ar_none_incr_burst_remaining  <= 1'b0;
        ar_none_fixed_burst_remaining <= 1'b0;
    end
    else if (phantom_start) begin
        ar_requests_remaining         <= ar_next_remaining_combo;
        ar_none_incr_burst_remaining  <= ar_none_incr_burst_remaining_combo;
        ar_none_fixed_burst_remaining <= ar_none_fixed_burst_remaining_combo;
    end
    else if (axi_abort_pending) begin
        ar_requests_remaining         <= 'b0;
        ar_none_incr_burst_remaining  <= 1'b1;
        ar_none_fixed_burst_remaining <= 1'b1;
    end
end

always @(*) begin
    // ar_requests_remaining - (M_AXI_ARLEN + 1)
    ar_next_remaining_combo                  = ar_requests_remaining - ({(LGMAXBURST+1){phantom_start}} & rd_max_burst);
    ar_next_full_incr_burst_remaining_combo  = |ar_next_remaining_combo[AWT-1 : LGMAXBURST];
    ar_next_full_fixed_burst_remaining_combo = |ar_next_remaining_combo[AWT-1 : LGMAX_FIXED_BURST];
    ar_none_incr_burst_remaining_combo       = !ar_next_full_incr_burst_remaining_combo && !(|ar_next_remaining_combo[LGMAXBURST-1 : 0]);
    ar_none_fixed_burst_remaining_combo      = !ar_next_full_fixed_burst_remaining_combo && !(|ar_next_remaining_combo[LGMAX_FIXED_BURST-1 : 0]);
end

// axi_araddr
always @(posedge M_AXI_ACLK) begin
    if (!r_busy) begin
        axi_araddr <= araddr;
    end
    else if (arfire) begin
        axi_araddr[ADDRLSB-1 : 0] <= 'b0;
        if (ar_incr_burst) begin
            axi_araddr[AW-1 : ADDRLSB] <=axi_araddr[AW-1 : ADDRLSB] + rd_max_burst; 
        end
    end
end

// axi_rready
always @(posedge M_AXI_ACLK) begin
    if (!M_AXI_ARESETN) begin
        axi_rready <= 1'b0;
    end 
    else if (arfire) begin
        axi_rready <= 1'b1;
    end
    else if (r_complete_combo) begin
        axi_rready <= 1'b0;
    end
end

assign r_cmd_ready   = !r_busy && !axi_abort_pending;
assign r_cmd_abort   = axi_abort_pending;

assign M_AXI_ARVALID = axi_arvalid;
assign M_AXI_ARADDR  = axi_araddr;
assign M_AXI_ARID    = axi_arid;
assign M_AXI_ARBURST = axi_arburst;
assign M_AXI_ARSIZE  = axi_arsize;
assign M_AXI_ARLEN   = axi_arlen;

assign M_AXI_RREADY  = axi_rready;

endmodule












