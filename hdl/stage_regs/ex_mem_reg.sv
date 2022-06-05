`ifndef EX_MEM_REG_SV
`define EX_MEM_REG_SV

// `include "../rv32i_types.sv"

import rv32i_types::*;

module ex_mem_reg(
    input clk,
    input rst,
    input load,

    input [31:0] pc_i,
    input [31:0] pc_next_i,

    input [31:0] ir_i,
    input [31:0] alu_i,
    input        br_en_i,
    input [31:0] rs2_val_i,
    input control_word_t ctrl_wd_i,

    output [31:0] pc_o,
    output [31:0] pc_next_o,

    output [31:0] ir_o,
    output [31:0] alu_o,
    output        br_en_o,
    output [31:0] u_imm,
    output [4:0]  rs2,
    output [4:0]  rd,
    output [31:0] rs2_val_o,
    output control_word_t ctrl_wd_o
);

logic [31:0] pc_;
logic [31:0] pc_next_;

logic [31:0] ir_;
logic [31:0] alu_;
logic        br_en_;
logic [31:0] rs2_val_;
control_word_t ctrl_wd_;

assign pc_o    = pc_;
assign ir_o    = ir_;
assign alu_o   = alu_;
assign br_en_o = br_en_;
assign u_imm   = {ir_[31:12], 12'h000};
assign rs2       = ir_[24:20];
assign rd        = ir_[11:7];
assign rs2_val_o = rs2_val_;
assign ctrl_wd_o = ctrl_wd_;

assign pc_next_o = pc_next_;


always_ff @(posedge clk)
begin
    if (rst)
    begin
        pc_      <= '0;
        ir_      <= '0;
        ctrl_wd_ <= '0;
        alu_     <= '0;
        br_en_   <= '0;
        rs2_val_ <= '0;
        pc_next_ <= '0;    
    end
    else if (load == 1'b1)
    begin
        pc_      <= pc_i;
        ir_      <= ir_i;
        ctrl_wd_ <= ctrl_wd_i;
        alu_     <= alu_i;
        br_en_   <= br_en_i;
        rs2_val_ <= rs2_val_i;
        pc_next_ <= pc_next_i;
    end
    else
    begin
        pc_      <= pc_;
        ir_      <= ir_;
        ctrl_wd_ <= ctrl_wd_;
        alu_     <= alu_;
        br_en_   <= br_en_;
        rs2_val_ <= rs2_val_;
        pc_next_ <= pc_next_;
    end
end

endmodule : ex_mem_reg

`endif
