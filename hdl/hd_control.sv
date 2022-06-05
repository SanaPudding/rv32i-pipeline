`include "rv32i_types.sv"

import rv32i_types::*;

module hd_control
(
    input rv32i_opcode ifid_opcode,
    input rv32i_opcode idex_opcode,
    input logic [4:0]  idex_rd,
    input logic [4:0]  ifid_rs1,
    input logic [4:0]  ifid_rs2,

    input logic do_jump,
    input logic is_ujump,
    input logic br_en,

    output logic lu_hazard
    // output logic br_hazard
);

always_comb
begin
    // load-use hazard detection
    if (idex_opcode == op_load) begin
        if (ifid_rs1 == idex_rd) begin
            if (ifid_opcode == op_jalr ||
                ifid_opcode == op_br ||
                ifid_opcode == op_load ||
                ifid_opcode == op_store ||
                ifid_opcode == op_imm ||
                ifid_opcode == op_reg) lu_hazard = 1'b1;
            else                       lu_hazard = 1'b0;
        end else if (ifid_rs2 == idex_rd) begin
            if (ifid_opcode == op_br ||
                ifid_opcode == op_store ||
                ifid_opcode == op_imm ||
                ifid_opcode == op_reg) lu_hazard = 1'b1;
            else                       lu_hazard = 1'b0;
        end else lu_hazard = 1'b0;
    end else lu_hazard = 1'b0;

    // branch hazard detection
    // if (do_jump & (is_ujump | br_en)) br_hazard = 1'b1;
    // else                              br_hazard = 1'b0;
end
    
endmodule : hd_control