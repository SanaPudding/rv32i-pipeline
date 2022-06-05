`ifndef ID_EX_REG_SV
`define ID_EX_REG_SV

// `include "../rv32i_types.sv"

import rv32i_types::*;

module id_ex_reg(
    input clk,
    input rst,
    input load,

    input [31:0] pc_i,

    input [31:0] ir_i,
    input [31:0] rs1_val_i,
    input [31:0] rs2_val_i,
    input control_word_t ctrl_wd_i,
    
    output [31:0] i_imm,
    output [31:0] s_imm,
    output [31:0] b_imm,
    output [31:0] u_imm,
    output [31:0] j_imm,

    output [31:0] pc_o,
    output [31:0] ir_o,
    output [31:0] rs1_val_o,
    output [31:0] rs2_val_o,
    output [4:0]  rs1,
    output [4:0]  rs2,
    output [4:0]  rd,
    output control_word_t ctrl_wd_o
);

// registers
logic[31:0] pc_;
logic[31:0] ir_;
logic[31:0] rs1_val_;
logic[31:0] rs2_val_;
control_word_t ctrl_wd_;

assign i_imm = {{21{ir_[31]}}, ir_[30:20]};
assign s_imm = {{21{ir_[31]}}, ir_[30:25], ir_[11:7]};
assign b_imm = {{20{ir_[31]}}, ir_[7], ir_[30:25], ir_[11:8], 1'b0};
assign u_imm = {ir_[31:12], 12'h000};
assign j_imm = {{12{ir_[31]}}, ir_[19:12], ir_[20], ir_[30:21], 1'b0};
assign rs1   = ir_[19:15];
assign rs2   = ir_[24:20];
assign rd    = ir_[11:7];

assign pc_o = pc_;
assign ir_o = ir_;
assign rs1_val_o = rs1_val_;
assign rs2_val_o = rs2_val_;
assign ctrl_wd_o = ctrl_wd_;

always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc_      <= '0;
        ir_      <= '0;
        ctrl_wd_ <= '0;
        rs1_val_ <= '0;
        rs2_val_ <= '0;
    end
    else if (load == 1'b1)
    begin
        pc_      <= pc_i;
        ir_      <= ir_i;
        ctrl_wd_ <= ctrl_wd_i;
        rs1_val_ <= rs1_val_i;
        rs2_val_ <= rs2_val_i;
    end
    else
    begin
        pc_      <= pc_;
        ir_      <= ir_;
        ctrl_wd_ <= ctrl_wd_;  
        rs1_val_ <= rs1_val_;
        rs2_val_ <= rs2_val_;
    end
end

endmodule : id_ex_reg

`endif
