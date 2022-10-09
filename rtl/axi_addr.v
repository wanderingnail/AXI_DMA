module axi_addr #(
    parameter AW = 32,
    parameter DW = 32
)(
    input  [AW-1 : 0] i_last_addr,
    input  [2 : 0]    i_size,
    input  [1 : 0]    i_burst,
    input  [7 : 0]    i_len,
    output [AW-1 : 0] o_next_addr
);

localparam DSZ = $clog2(DW) - 3;

localparam FIXED     = 2'b00,
           INCREMENT = 2'b01,
           WRAP      = 2'b10;

reg [AW-1 : 0] wrap_mask, increment;

// increment
always @(*) begin
    increment = 0;
    if (i_burst != FIXED) begin
        if (DSZ == 0) begin
            increment = 1;
        end
        else if (DSZ == 1) begin
            increment = i_size[0] ? 2 : 1;
        end
        else if (DSZ == 2) begin
            increment = i_size[1] ? 4 : (i_size[0] ? 2 : 1);
        end
        else if (DSZ == 4) begin
            case (i_size[1 : 0])
                2'b00: increment = 1;
                2'b01: increment = 2;
                2'b10: increment = 4;
                2'b11: increment = 8;
            endcase
        end
        else begin
            increment = (1 << i_size);
        end
    end
end

// wrap_mask
always @(*) begin
    wrap_mask = 'b0;
    if (i_burst == WRAP) begin
        if (i_len == 1) begin
            wrap_mask = (1 << (i_size + 1));
        end
        else if (i_len == 3) begin
            wrap_mask = (1 << (i_size + 2));
        end
        else if (i_len == 7) begin
            wrap_mask = (1 << (i_size + 3));
        end
        else if (i_len == 15) begin
            wrap_mask = (1 << (i_size + 4));
        end

        wrap_mask = wrap_mask - 1;

        if (AW > 12) begin
            wrap_mask[(AW-1) : ((AW >12) ? 12 : (AW-1))] = 'b0;
        end
    end
end

// next_addr, aligned addess
always @(*) begin
    o_next_addr = i_last_addr + increment;
    if (i_burst != FIXED) begin
        if (DSZ < 2) begin
            o_next_addr = i_size[0];
        end
        else if (DSZ < 4) begin
            case(i_size[1 : 0]) 
                2'b00: o_next_addr        = o_next_addr;
                2'b01: o_next_addr[0]     = 1'b0;
                2'b10: o_next_addr[1 : 0] = 'b0;
                2'b11: o_next_addr[2 : 0] = 'b0;
            endcase
        end
        else begin
            case(i_size) 
                3'b000: o_next_addr        = o_next_addr;
                3'b001: o_next_addr[0]     = 1'b0;
                3'b010: o_next_addr[1 : 0] = 'b0;
                3'b011: o_next_addr[2 : 0] = 'b0;
                3'b100: o_next_addr[3 : 0] = 'b0;
                3'b101: o_next_addr[4 : 0] = 'b0;
                3'b110: o_next_addr[5 : 0] = 'b0;
                3'b111: o_next_addr[6 : 0] = 'b0;
            endcase
        end
    end
    if (i_burst[i]) begin
        o_next_addr = (i_last_addr & ~wrap_mask) | (o_next_addr & wrap_mask);
    end
    if (AW > 12) begin
        o_next_addr[(AW-1) : ((AW >12) ? 12 : (AW-1))] = i_last_addr[(AW-1) : ((AW >12) ? 12 : (AW-1))];
    end
end

endmodule

                



                            
    