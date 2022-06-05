import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input rv32i_word rs1,
    input rv32i_word cmpmux_out,
    output logic br_en
);
/*
Floating-point compare instructions perform the specified comparison 
(equal, less than, or less than or equal) 
etween floating-point registers rs1 and rs2 
and record the Boolean result in integer register rd.
*/
always_comb
begin
    unique case (cmpop)
    beq:     br_en = (rs1 == cmpmux_out);
    bne:     br_en = (rs1 != cmpmux_out);
    blt:     br_en = ($signed(rs1) < $signed(cmpmux_out));
    bge:     br_en = ($signed(rs1) >= $signed(cmpmux_out));
    bltu:    br_en = (rs1 < cmpmux_out);
    bgeu:    br_en = (rs1 >= cmpmux_out);
    default: br_en = 1'b0;
    endcase
end

endmodule : cmp