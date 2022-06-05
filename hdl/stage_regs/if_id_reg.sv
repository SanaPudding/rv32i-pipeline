`ifndef IF_ID_REG_SV
`define IF_ID_REG_SV

// `include "../rv32i_types.sv"

import rv32i_types::*;

module if_id_reg(
    input clk,
    input rst,
    input load,

    input [31:0] pc_i,
    input [31:0] ir_i,

    output [31:0] pc_o,
    output [31:0] ir_o,
    output rv32i_opcode opcode,
    output [2:0] funct3,
    output [6:0] funct7,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd
);

logic[31:0] pc_;
logic[31:0] ir_;

assign pc_o = pc_;
assign ir_o = ir_;
assign opcode = rv32i_opcode'(ir_[6:0]);
assign funct3 = ir_[14:12];
assign funct7 = ir_[31:25];
assign rs1    = ir_[19:15];
assign rs2    = ir_[24:20];
assign rd     = ir_[11:7];

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc_ <= '0;
        ir_ <= '0;
    end
    else if (load == 1'b1)
    begin
        pc_ <= pc_i;
        ir_ <= ir_i;
    end
    else
    begin
        pc_ <= pc_;
        ir_ <= ir_;
    end
end

endmodule : if_id_reg

`endif
