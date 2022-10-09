`timescale 1ns / 1ns
module tb_axi_top;

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

initial begin
    $dumpfile("axi_top.vcd");
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
    #3;
    rst_n = 1;
    #40000;
    $finish;
end

initial begin
    cmd_valid = 1'b1;
    cmd_addr  = {{8{1'b0}}, {8{1'b1}}};
    cmd_id    = 'b0;
    cmd_len   = 1052;
    cmd_size  = 3'b010;
    cmd_burst = 2'b01;
    #20000;
    cmd_valid = 1'b1;
end

always @(posedge clk) begin
    if (cmd_valid && cmd_ready) begin
        cmd_valid <= 1'b0;
    end
end

axi_top #(
    .AXI_ID_WD(AXI_ID_WD),
    .AXI_DATA_WD(AXI_DATA_WD),
    .AXI_ADDR_WD(AXI_ADDR_WD),
    .AXI_STRB_WD(AXI_STRB_WD)
) axi_top (
    .AXI_ACLK(clk),
    .AXI_ARESETN(rst_n),    
    .cmd_valid(cmd_valid),
    .cmd_addr(cmd_addr),
    .cmd_id(cmd_id),
    .cmd_burst(cmd_burst),
    .cmd_size(cmd_size),
    .cmd_len(cmd_len),
    .cmd_ready(cmd_ready),
    .cmd_abort(cmd_abort)
);

endmodule