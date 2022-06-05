import rv32i_types::*;

module branch_control_local
(
    input clk,
    input rst,

    // IF signals
    input [31:0] pc,

    // EX signals
    input do_jump,
    input is_ujump,
    input br_en,
    input [31:0] true_addr,
    input [31:0] pc_idex,

    input load_ifid,
    input load_idex,
    input ifid_rst,
    input idex_rst,

    output logic [31:0] pred_addr,
    output logic [31:0] recv_addr,
    output logic br_hazard
);

logic load_tag, load_btb, load_bht;
logic [3:0]  rindex, windex;
logic [3:0]  idx_ifid, idx_idex;
logic [25:0] tag_in, tag_out;
logic [31:0] btb_in, btb_out, addr_ifid, addr_idex;
logic        bht_in, bht_out, cond_ifid, cond_idex, pred_cond;

assign rindex = pc[5:2];
assign windex = idx_idex;
assign tag_in = pc_idex[31:6];
assign btb_in = true_addr;

assign pred_cond = bht_out & (pc[31:6] == tag_out);
assign pred_addr = pred_cond ? btb_out : (pc + 4);

always_comb
begin : btb_bht_update_logic
    // default assignments
    br_hazard = 1'b0;
    recv_addr = true_addr;
    bht_in    = 1'b0;
    load_tag  = 1'b0;
    load_btb  = 1'b0;
    load_bht  = 1'b0;

    // if is a (branch or jump) inst
    if (do_jump) begin
        // indeed taken
        if (is_ujump | br_en) begin
            if (cond_idex) begin
                if (addr_idex == true_addr) ;
                else begin
                    br_hazard = 1'b1;
                    load_btb  = 1'b1;
                end
            end
            else begin
                br_hazard = 1'b1;
                bht_in    = 1'b1;
                load_tag  = 1'b1;
                load_btb  = 1'b1;
                load_bht  = 1'b1;
            end
        end
        // indeed not taken
        else begin
            if (cond_idex) begin
                br_hazard = 1'b1;
                recv_addr = pc_idex + 4;
                load_bht  = 1'b1;
            end
            else ;
        end
    end
    // if is NOT a (branch or jump) inst
    else begin
        if (cond_idex) begin
            br_hazard = 1'b1;
            recv_addr = pc_idex + 4;
            load_bht  = 1'b1;
        end
        else ;
    end
end

// tag array
array_16set #(26) tag (clk, rst, load_tag, rindex, windex, tag_in, tag_out);
// branch target buffer (hold predictive pc address)
array_16set #(32) btb (clk, rst, load_btb, rindex, windex, btb_in, btb_out);
// branch history table (hold predictive condition)
array_16set #(1)  bht (clk, rst, load_bht, rindex, windex, bht_in, bht_out);

// stage regs
bc_stage_reg ifid (clk, ifid_rst, load_ifid, rindex,   pred_cond, btb_out,   idx_ifid, cond_ifid, addr_ifid);
bc_stage_reg idex (clk, idex_rst, load_idex, idx_ifid, cond_ifid, addr_ifid, idx_idex, cond_idex, addr_idex);

endmodule : branch_control_local
