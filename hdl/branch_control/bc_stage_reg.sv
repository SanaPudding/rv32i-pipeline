import rv32i_types::*;

module bc_stage_reg
#(parameter idx_width = 4)
(
    input clk,
    input rst,
    input load,

    input [idx_width-1:0] btb_idx_in,
    input [idx_width-1:0] bht_idx_in,
    input        cond_in,
    input [31:0] addr_in,

    output logic [idx_width-1:0] btb_idx_out,
    output logic [idx_width-1:0] bht_idx_out,
    output logic        cond_out,
    output logic [31:0] addr_out
);

logic [idx_width-1:0] btb_idx, bht_idx;
logic        cond;
logic [31:0] addr;

always_ff @(posedge clk)
begin
    if (rst) begin
        btb_idx <= '0;
        bht_idx <= '0;
        cond <= '0;
        addr <= '0;
    end
    else begin
        if (load) begin
            btb_idx <= btb_idx_in;
            bht_idx <= bht_idx_in;
            cond <= cond_in;
            addr <= addr_in;
        end
        else begin
            btb_idx <= btb_idx;
            bht_idx <= bht_idx;
            cond <= cond;
            addr <= addr;
        end
    end
end

always_comb
begin
    btb_idx_out <= btb_idx;
    bht_idx_out <= bht_idx;
    cond_out = cond;
    addr_out = addr;
end

endmodule : bc_stage_reg
