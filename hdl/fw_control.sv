`include "rv32i_types.sv"

import rv32i_types::*;

module fw_control
(
    // input rv32i_opcode idex_opcode,
    // input rv32i_opcode exmem_opcode,
    input logic exmem_load_regfile,
    input logic memwb_load_regfile,
    input rv32i_opcode idex_opcode,
    input rv32i_opcode exmem_opcode,

    input logic [4:0] idex_rs1,
    input logic [4:0] idex_rs2,
    input logic [4:0] exmem_rs2,
    input logic [4:0] exmem_rd,
    input logic [4:0] memwb_rd,

    output logic [1:0] ex_rs1mux_sel,
    output logic [1:0] ex_rs2mux_sel
);

always_comb
begin
    /* default assignment */
    ex_rs1mux_sel  = ex_rsmux::id_ex;
    ex_rs2mux_sel  = ex_rsmux::id_ex;

    /* assign ex_rs1 mux selection signal */
    /* 
       NOTE: lui, auipc, jal does not use rs1 at EX, so it's ok to assign any value
       to rs1, since it will be ignored anyway (thru other mux selection sigs)
    */
    /* 
       NOTE: since if statement enforces priority, double data hazard is therefore
       resovled by checking againt EX/MEM reg first, then MEM/WB reg.
     */
    if (idex_rs1 == exmem_rd) begin
        if (exmem_load_regfile && (exmem_rd != 0)) ex_rs1mux_sel = ex_rsmux::ex_mem;
        else                                       ex_rs1mux_sel = ex_rsmux::id_ex;
    end else if (idex_rs1 == memwb_rd) begin
        if (memwb_load_regfile && (memwb_rd != 0)) ex_rs1mux_sel = ex_rsmux::mem_wb;
        else                                       ex_rs1mux_sel = ex_rsmux::id_ex;
    end else ;

    /* assign ex_rs2 mux selection signal */
    /*
       NOTE: lui, auipc, jal, jalr, load, imm instructions do not use rs2 at EX,
             br, store, reg instructions use rs2 at EX.
    */
    if (idex_rs2 == exmem_rd) begin
        if (exmem_load_regfile && (exmem_rd != 0)) ex_rs2mux_sel = ex_rsmux::ex_mem;
        else                                       ex_rs2mux_sel = ex_rsmux::id_ex;
    end else if (idex_rs2 == memwb_rd) begin
        if (memwb_load_regfile && (memwb_rd != 0)) ex_rs2mux_sel = ex_rsmux::mem_wb;
        else                                       ex_rs2mux_sel = ex_rsmux::id_ex;
    end else ;
end
    
endmodule : fw_control