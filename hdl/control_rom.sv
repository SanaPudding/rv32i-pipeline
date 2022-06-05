`define BAD_REGFILEMUX_SEL $fatal("%0t %s %0d: Illegal regfilemux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

module control_rom(
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    output control_word_t ctrl
);

function void set_defaults();
    ctrl.opcode         = opcode;
    ctrl.funct3         = funct3;
    ctrl.alumux1_sel    = alumux::rs1_out;
    ctrl.alumux2_sel    = alumux::i_imm;
    ctrl.cmpmux_sel     = cmpmux::rs2_out;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.aluop          = alu_ops'(funct3);
    ctrl.cmpop          = branch_funct3_t'(funct3);
    ctrl.load_regfile   = 1'b0;
    ctrl.data_read      = 1'b0;
    ctrl.data_write     = 1'b0;
    ctrl.do_jump        = 1'b0;
    ctrl.is_ujump       = 1'b0;
endfunction

always_comb
begin : control_word_logic
    /* default assignments */
    set_defaults();

    /* assign control signals based on opcode */
    unique case (opcode)
        op_lui: begin
            ctrl.regfilemux_sel = regfilemux::u_imm;
            ctrl.load_regfile = 1'b1;
        end

        op_auipc: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::u_imm;
            ctrl.regfilemux_sel = regfilemux::alu_out;
            ctrl.load_regfile = 1'b1;
        end

        op_jal: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::j_imm;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = 1'b1;
            ctrl.do_jump  = 1'b1;
            ctrl.is_ujump = 1'b1;
        end

        // NOTE: least sig bit of alu_out should be set to 0
        op_jalr: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.regfilemux_sel = regfilemux::pc_plus4;
            ctrl.load_regfile = 1'b1;
            ctrl.do_jump  = 1'b1;
            ctrl.is_ujump = 1'b1;
        end

        op_br: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::pc_out;
            ctrl.alumux2_sel = alumux::b_imm;
            ctrl.cmpmux_sel = cmpmux::rs2_out;
            ctrl.cmpop = branch_funct3_t'(funct3);
            ctrl.do_jump  = 1'b1;
            ctrl.is_ujump = 1'b0;
        end

        op_load: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.data_read = 1'b1;
            ctrl.load_regfile = 1'b1;
            case (load_funct3_t'(funct3))
                lb:  ctrl.regfilemux_sel = regfilemux::lb;
                lh:  ctrl.regfilemux_sel = regfilemux::lh;
                lw:  ctrl.regfilemux_sel = regfilemux::lw;
                lbu: ctrl.regfilemux_sel = regfilemux::lbu;
                lhu: ctrl.regfilemux_sel = regfilemux::lhu;
                default: `BAD_REGFILEMUX_SEL;
            endcase
            // funct3 default
        end

        op_store: begin
            ctrl.aluop = alu_add;
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::s_imm;
            ctrl.data_write = 1'b1;
            // funct3 default
        end

        op_imm: begin
            /* for ADDI, XORI, ORI, ANDI, SLLI instructions, default setting is fine */
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::i_imm;
            ctrl.load_regfile = 1'b1;

            case (arith_funct3_t'(funct3))
                slt: begin
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.cmpop = rv32i_types::blt;
                end
                sltu: begin
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpmux_sel = cmpmux::i_imm;
                    ctrl.cmpop = rv32i_types::bltu;
                end
                sr: begin
                    if (funct7[5]) ctrl.aluop = alu_sra; // sra
                    else           ctrl.aluop = alu_srl; // srl
                end
					 default: ;
            endcase
        end

        op_reg: begin
            // sll, xor, or, and
            ctrl.alumux1_sel = alumux::rs1_out;
            ctrl.alumux2_sel = alumux::rs2_out;
            ctrl.load_regfile = 1'b1;

            case (funct3)
                add: begin
                    if (funct7[5]) ctrl.aluop = alu_sub; // sub
                    else           ctrl.aluop = alu_add; // add
                end
                slt: begin
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpop = rv32i_types::blt;
                end
                sltu: begin
                    ctrl.regfilemux_sel = regfilemux::br_en;
                    ctrl.cmpop = rv32i_types::bltu;
                end
                sr: begin
                    if (funct7[5]) ctrl.aluop = alu_sra; // sra
                    else           ctrl.aluop = alu_srl; // srl
                end
					 default: ;
            endcase
        end

        default: ctrl = 0; // NOTE: may have syntax error
    endcase
end

endmodule : control_rom
