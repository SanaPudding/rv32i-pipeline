`define BAD_MUX_SEL   $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;

`include "stage_regs/if_id_reg.sv"
`include "stage_regs/id_ex_reg.sv"
`include "stage_regs/ex_mem_reg.sv"
`include "stage_regs/mem_wb_reg.sv"

module datapath(
    input clk,
    input rst,

    output logic inst_read,
    output logic [31:0] inst_addr,
    input  logic inst_resp,
    input  logic [31:0] inst_rdata,

    output logic data_read,
    output logic data_write,
    output logic [3:0]  data_mbe,
    output logic [31:0] data_addr,
    output logic [31:0] data_wdata,
    input  logic data_resp,
    input  logic [31:0] data_rdata,

    output logic halt,
    output logic trap,
    output logic commit,
    output monitor_signals monitor
);

/*----- IF/ID stage signals -----*/
logic load_pc;
logic [1:0]  pcmux_sel;
logic [31:0] pcmux_out;
logic [31:0] pc_out;

logic load_ifid;
logic [31:0] ifid_pc;
logic [31:0] ifid_ir;
rv32i_opcode ifid_opcode;
logic [2:0]  ifid_funct3;
logic [6:0]  ifid_funct7;
logic [4:0]  ifid_rs1;
logic [4:0]  ifid_rs2;
logic [4:0]  ifid_rd;

/*----- ID/EX stage signals -----*/
logic [31:0] rs1_out;
logic [31:0] rs2_out;
logic [31:0] regfilemux_out;

// control rom signal
control_word_t ctrl_wd;

// ID_EX
logic load_idex;
logic [31:0] idex_i_imm;
logic [31:0] idex_s_imm;
logic [31:0] idex_b_imm;
logic [31:0] idex_u_imm;
logic [31:0] idex_j_imm;
logic [4:0]  idex_rs1;
logic [4:0]  idex_rs2;
logic [4:0]  idex_rd;
logic [31:0] idex_pc;
logic [31:0] idex_ir;
logic [31:0] idex_rs1_val;
logic [31:0] idex_rs2_val;
control_word_t idex_ctrl_wd;

/*----- EX/MEM stage signals -----*/
// mux outs
logic [31:0] alumux1_out;
logic [31:0] alumux2_out;
logic [31:0] cmpmux_out;

// ALU and CMP
logic [31:0] alu_out;
logic br_en;

// EX_MEM
logic load_exmem;
logic [31:0] exmem_pc;
logic [31:0] exmem_ir;
logic [31:0] exmem_alu;
logic        exmem_br_en;
logic [31:0] exmem_u_imm;
logic [4:0]  exmem_rs2;
logic [4:0]  exmem_rd;
logic [31:0] exmem_rs2_val;
logic [31:0] exmem_rd_val;
control_word_t exmem_ctrl_wd;

/*----- MEM/WB stage signals -----*/
// MEM_WB
logic load_memwb;
logic [31:0] memwb_pc;
logic [31:0] memwb_ir;
logic [31:0] memwb_alu;
logic        memwb_br_en;
logic [31:0] memwb_rdata;
logic [31:0] memwb_u_imm;
logic [4:0]  memwb_rd;
control_word_t memwb_ctrl_wd;

/*----- forwarding unit signals -----*/
logic [1:0]  ex_rs1mux_sel;
logic [1:0]  ex_rs2mux_sel;
logic [31:0] ex_rs1mux_out;
logic [31:0] ex_rs2mux_out;

// logic        mem_rs2mux_sel;
logic [31:0] mem_rs2mux_out;

/*----- hazard detection unit signals -----*/
logic lu_hazard;
logic br_hazard;
logic inst_ready;
logic data_ready;

logic ifid_rst;
logic idex_rst;
logic exmem_rst;
logic memwb_rst;

logic [31:0] exmem_pcn, memwb_pcn;
logic [31:0] pred_addr, recv_addr;

/*----- signal assignments -----*/
assign inst_addr  = pc_out;
assign inst_read  = 1'b1;

assign inst_ready = inst_resp;
assign data_ready = data_resp | (~exmem_ctrl_wd.data_read & ~exmem_ctrl_wd.data_write);

assign load_pc    = inst_ready & data_ready & (~lu_hazard);
assign load_ifid  = inst_ready & data_ready & (~lu_hazard);
assign load_idex  = inst_ready & data_ready;
assign load_exmem = inst_ready & data_ready;
assign load_memwb = inst_ready & data_ready;

assign ifid_rst  = rst |  (br_hazard & inst_ready & data_ready);
assign idex_rst  = rst | ((br_hazard | lu_hazard) & inst_ready & data_ready);
assign exmem_rst = rst;
assign memwb_rst = rst;

always_comb
begin
    if (br_hazard) pcmux_sel = pcmux::alu_out;
    else           pcmux_sel = pcmux::pc_plus4;
end

/******************************* IF *********************************/
always_comb
begin
    unique case (pcmux_sel)
        pcmux::pc_plus4:    pcmux_out = pred_addr;
        pcmux::alu_out:     pcmux_out = recv_addr;
        default: pcmux_out = '0;
    endcase
end

pc_register PC(
    .clk    (clk),
    .rst    (rst),
    .load   (load_pc),
    .in     (pcmux_out),
    .out    (pc_out)
);

if_id_reg IF_ID(
    /************ inputs ************/
    .clk    (clk),
    .rst    (ifid_rst),
    .load   (load_ifid),
    .pc_i   (pc_out),
    .ir_i   (inst_rdata),

    /************ outputs ************/
    .pc_o   (ifid_pc),
    .ir_o   (ifid_ir),
    .opcode (ifid_opcode),
    .funct3 (ifid_funct3),
    .funct7 (ifid_funct7),
    .rs1    (ifid_rs1),
    .rs2    (ifid_rs2),
    .rd     (ifid_rd)
);

/******************************* ID *********************************/
regfile regfile(
    /************ inputs ************/
    .clk    (clk),
    .rst    (rst),
    .load   (memwb_ctrl_wd.load_regfile),
    .in     (regfilemux_out),
    .src_a  (ifid_rs1),
    .src_b  (ifid_rs2),
    .dest   (memwb_rd),

    /************ outputs ************/
    .reg_a  (rs1_out),
    .reg_b  (rs2_out)
);

control_rom control_rom(
    /************ inputs ************/
    .opcode (ifid_opcode),
    .funct3 (ifid_funct3),
    .funct7 (ifid_funct7),

    /************ outputs ************/
    .ctrl   (ctrl_wd)
);

id_ex_reg ID_EX(
    /************ inputs ************/
    .clk       (clk),
    .rst       (idex_rst),
    .load      (load_idex),
    .pc_i      (ifid_pc),
    .ir_i      (ifid_ir),
    .rs1_val_i (rs1_out),
    .rs2_val_i (rs2_out),
    .ctrl_wd_i (ctrl_wd),

    /************ outputs ************/
    .i_imm     (idex_i_imm),
    .s_imm     (idex_s_imm),
    .b_imm     (idex_b_imm),
    .u_imm     (idex_u_imm),
    .j_imm     (idex_j_imm),
    .rs1       (idex_rs1),
    .rs2       (idex_rs2),
    .rd        (idex_rd),
    .pc_o      (idex_pc),
    .ir_o      (idex_ir),
    .rs1_val_o (idex_rs1_val),
    .rs2_val_o (idex_rs2_val),
    .ctrl_wd_o (idex_ctrl_wd)
);

/******************************* EX *********************************/
always_comb
begin
    unique case (idex_ctrl_wd.alumux1_sel)
        alumux::rs1_out:    alumux1_out = ex_rs1mux_out;
        alumux::pc_out:     alumux1_out = idex_pc;
        default: alumux1_out = '0;
    endcase

    unique case (idex_ctrl_wd.alumux2_sel)
        alumux::i_imm:      alumux2_out = idex_i_imm;
        alumux::u_imm:      alumux2_out = idex_u_imm;
        alumux::b_imm:      alumux2_out = idex_b_imm;
        alumux::s_imm:      alumux2_out = idex_s_imm;
        alumux::j_imm:      alumux2_out = idex_j_imm;
        alumux::rs2_out:    alumux2_out = ex_rs2mux_out;
        default: `BAD_MUX_SEL;
    endcase

    unique case (idex_ctrl_wd.cmpmux_sel)
        cmpmux::rs2_out:    cmpmux_out = ex_rs2mux_out;
        cmpmux::i_imm:      cmpmux_out = idex_i_imm;
        default: cmpmux_out = '0;
    endcase
end

alu ALU(
    .aluop (idex_ctrl_wd.aluop),
    .a     (alumux1_out),
    .b     (alumux2_out),
    .f     (alu_out)
);

cmp CMP(
    .rs1        (ex_rs1mux_out),
    .cmpop      (idex_ctrl_wd.cmpop),
    .cmpmux_out (cmpmux_out),
    .br_en      (br_en)
);

ex_mem_reg EX_MEM(
    /************ inputs ************/
    .clk        (clk),
    .rst        (exmem_rst),
    .load       (load_exmem),
    .pc_i       (idex_pc),
    .ir_i       (idex_ir),
    .alu_i      (alu_out),
    .br_en_i    (br_en),
    .rs2_val_i  (ex_rs2mux_out),
    .ctrl_wd_i  (idex_ctrl_wd),

    /************ outputs ************/
    .pc_o       (exmem_pc),
    .ir_o       (exmem_ir),
    .alu_o      (exmem_alu),
    .br_en_o    (exmem_br_en),
    .u_imm      (exmem_u_imm),
    .rs2        (exmem_rs2),
    .rd         (exmem_rd),
    .rs2_val_o  (exmem_rs2_val),
    .ctrl_wd_o  (exmem_ctrl_wd),

    .pc_next_i  (pcmux_out),
    .pc_next_o  (exmem_pcn)
);

/******************************* MEM ********************************/
/* data logic and byte enable */
assign data_read  = exmem_ctrl_wd.data_read;
assign data_write = exmem_ctrl_wd.data_write;
assign data_addr  = {exmem_alu[31:2], 2'd0};
assign data_wdata = exmem_rs2_val << (exmem_alu[1:0] * 8);

always_comb
begin : data_mbe_logic
    /* default assignment */
    data_mbe   = '0;

    /* assign data_mbe signal based on ld/st */
    case (exmem_ctrl_wd.opcode)
        op_load: begin
            unique case (load_funct3_t'(exmem_ctrl_wd.funct3))
                lb:  data_mbe = 4'b0001 << (exmem_alu[1:0]);
                lh:  data_mbe = 4'b0011 << {exmem_alu[1], 1'b0};
                lw:  data_mbe = 4'b1111;
                lbu: data_mbe = 4'b0001 << (exmem_alu[1:0]);
                lhu: data_mbe = 4'b0011 << {exmem_alu[1], 1'b0};
                default: data_mbe = 4'b0000;
            endcase
        end

        op_store: begin
            unique case (store_funct3_t'(exmem_ctrl_wd.funct3))
                sb: data_mbe = 4'b0001 << (exmem_alu[1:0]);
                sh: data_mbe = 4'b0011 << {exmem_alu[1], 1'b0};
                sw: data_mbe = 4'b1111;
                default: data_mbe = 4'b0000;
            endcase
        end
		  default: data_mbe = 4'b0000;
    endcase
end

mem_wb_reg MEM_WB(
    /************ inputs ************/
    .clk          (clk),
    .rst          (memwb_rst),
    .load         (load_memwb),
    .pc_i         (exmem_pc),
    .ir_i         (exmem_ir),
    .alu_i        (exmem_alu),
    .br_en_i      (exmem_br_en),
    .data_rdata_i (data_rdata),
    .ctrl_wd_i    (exmem_ctrl_wd),

    /************ outputs ************/
    .pc_o         (memwb_pc),
    .ir_o         (memwb_ir),
    .alu_o        (memwb_alu),
    .br_en_o      (memwb_br_en),
    .data_rdata_o (memwb_rdata),
    .u_imm        (memwb_u_imm),
    .rd           (memwb_rd),
    .ctrl_wd_o    (memwb_ctrl_wd),

    .pc_next_i    (exmem_pcn),
    .pc_next_o    (memwb_pcn)
);

/******************************* WB *********************************/
always_comb begin : MUXES
    unique case (memwb_ctrl_wd.regfilemux_sel)
        regfilemux::alu_out:    regfilemux_out = memwb_alu;
        regfilemux::br_en:      regfilemux_out = {31'd0, memwb_br_en};
        regfilemux::u_imm:      regfilemux_out = memwb_u_imm;
        regfilemux::pc_plus4:   regfilemux_out = memwb_pc + 4;
        regfilemux::lw:         regfilemux_out = memwb_rdata;
        regfilemux::lb: begin
            case (memwb_alu[1:0])
                2'b00: regfilemux_out = {{24{memwb_rdata[7]}},  memwb_rdata[7:0]};
                2'b01: regfilemux_out = {{24{memwb_rdata[15]}}, memwb_rdata[15:8]};
                2'b10: regfilemux_out = {{24{memwb_rdata[23]}}, memwb_rdata[23:16]};
                2'b11: regfilemux_out = {{24{memwb_rdata[31]}}, memwb_rdata[31:24]};
            endcase
        end
        regfilemux::lbu: begin
            case (memwb_alu[1:0])
                2'b00: regfilemux_out = {24'd0, memwb_rdata[7:0]};
                2'b01: regfilemux_out = {24'd0, memwb_rdata[15:8]};
                2'b10: regfilemux_out = {24'd0, memwb_rdata[23:16]};
                2'b11: regfilemux_out = {24'd0, memwb_rdata[31:24]};
            endcase
        end
        regfilemux::lh: begin
            case (memwb_alu[1])
                1'b0: regfilemux_out = {{16{memwb_rdata[15]}}, memwb_rdata[15:0]};
                1'b1: regfilemux_out = {{16{memwb_rdata[31]}}, memwb_rdata[31:16]};
            endcase
        end
        regfilemux::lhu: begin
            case (memwb_alu[1])
                1'b0: regfilemux_out = {16'd0, memwb_rdata[15:0]};
                1'b1: regfilemux_out = {16'd0, memwb_rdata[31:16]};
            endcase
        end
        default: `BAD_MUX_SEL;
    endcase 
end

/*----- hazard detection & branch control -----*/
hd_control hd_control(
    .ifid_opcode (ifid_opcode),
    .idex_opcode (idex_ctrl_wd.opcode),
    .idex_rd     (idex_rd),
    .ifid_rs1    (ifid_rs1),
    .ifid_rs2    (ifid_rs2),
    .do_jump     (idex_ctrl_wd.do_jump),
    .is_ujump    (idex_ctrl_wd.is_ujump),
    .br_en       (br_en),

    .lu_hazard   (lu_hazard)
    // .br_hazard   (br_hazard)
);

branch_control_global bc (
    .pc        (pc_out),
    .do_jump   (idex_ctrl_wd.do_jump),
    .is_ujump  (idex_ctrl_wd.is_ujump),
    .br_en     (br_en),
    .true_addr (alu_out),
    .pc_idex   (idex_pc),
    .*
);

/*----- forwarding -----*/
fw_control fw_control(
    .exmem_load_regfile (exmem_ctrl_wd.load_regfile),
    .memwb_load_regfile (memwb_ctrl_wd.load_regfile),
    .idex_opcode        (idex_ctrl_wd.opcode),
    .exmem_opcode       (exmem_ctrl_wd.opcode),
    .idex_rs1           (idex_rs1),
    .idex_rs2           (idex_rs2),
    .exmem_rs2          (exmem_rs2),
    .exmem_rd           (exmem_rd),
    .memwb_rd           (memwb_rd),

    .ex_rs1mux_sel      (ex_rs1mux_sel),
    .ex_rs2mux_sel      (ex_rs2mux_sel)
);

always_comb
begin
    /*----- forwarding muxes -----*/
    unique case (exmem_ctrl_wd.regfilemux_sel[1:0])
        exmem_rd_mux::alu_out:  exmem_rd_val = exmem_alu;
        exmem_rd_mux::br_en:    exmem_rd_val = {31'd0, exmem_br_en};
        exmem_rd_mux::u_imm:    exmem_rd_val = exmem_u_imm;
        exmem_rd_mux::pc_plus4: exmem_rd_val = exmem_pc;
    endcase

    unique case (ex_rs1mux_sel)
        ex_rsmux::id_ex:  ex_rs1mux_out = idex_rs1_val;
        ex_rsmux::ex_mem: ex_rs1mux_out = exmem_rd_val;
        ex_rsmux::mem_wb: ex_rs1mux_out = regfilemux_out;
        default: ex_rs1mux_out = '0;     // NOTE: May need modification
    endcase

    unique case (ex_rs2mux_sel)
        ex_rsmux::id_ex:  ex_rs2mux_out = idex_rs2_val;
        ex_rsmux::ex_mem: ex_rs2mux_out = exmem_rd_val;
        ex_rsmux::mem_wb: ex_rs2mux_out = regfilemux_out;
        default: ex_rs2mux_out = '0;     // NOTE: May need modification
    endcase
end

/*----- RVFI monitor -----*/
// (* translate_off *)

/*----- halt, commit, trap -----*/
assign commit = (memwb_ctrl_wd.opcode && inst_ready && data_ready) ? 1'b1 : 1'b0;
assign halt = ((memwb_pc == memwb_pcn) && (memwb_pc != 0) && memwb_ctrl_wd.do_jump) ? 1'b1 : 1'b0;

branch_funct3_t branch_funct3;
store_funct3_t  store_funct3;
load_funct3_t   load_funct3;

assign branch_funct3 = branch_funct3_t'(ifid_funct3);
assign load_funct3   = load_funct3_t'(ifid_funct3);
assign store_funct3  = store_funct3_t'(ifid_funct3);

always_comb
begin : trap_check
    trap = 0;

    case (ifid_opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr, no_op:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: ;
                lh, lhu: ;
                lb, lbu: ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: ;
                sh: ;
                sb: ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end

monitor_signals ifid_mon_in, ifid_mon_out;
monitor_signals idex_mon_in, idex_mon_out;
monitor_signals exmem_mon_in, exmem_mon_out;
monitor_signals memwb_mon_in, memwb_mon_out;

logic [31:0] exmem_pc_wdata;
logic [31:0] rvfi_mem_addr,  rvfi_mem_rdata, rvfi_mem_wdata;
logic [3:0]  rvfi_mem_rmask, rvfi_mem_wmask;
assign exmem_pc_wdata = br_hazard ? pcmux_out : idex_mon_out.pc_wdata;

always_comb
begin
    rvfi_mem_addr  = exmem_mon_out.mem_addr;
    rvfi_mem_rmask = '0;
    rvfi_mem_wmask = '0;
    rvfi_mem_rdata = exmem_mon_out.mem_rdata;
    rvfi_mem_wdata = exmem_mon_out.mem_wdata;

    if (exmem_ctrl_wd.opcode == op_load) begin
        rvfi_mem_addr  = data_addr;
        rvfi_mem_rmask = data_mbe;
        rvfi_mem_rdata = data_rdata;
    end
    else if (exmem_ctrl_wd.opcode == op_store) begin
        rvfi_mem_addr  = data_addr;
        rvfi_mem_wmask = data_mbe;
        rvfi_mem_wdata = data_wdata;
    end
    else ;
end

always_comb
begin : monitor_signal_assignments
    ifid_mon_in  = '{default:     0,
                    inst:         inst_rdata,
                    pc_rdata:     pc_out,
                    pc_wdata:     pcmux_out
                    };

    idex_mon_in  = '{default:     0,
                    inst:         ifid_mon_out.inst,
                    pc_rdata:     ifid_mon_out.pc_rdata,
                    pc_wdata:     ifid_mon_out.pc_wdata,
                    rs1_addr:     ifid_rs1,
                    rs2_addr:     ifid_rs2,
                    rd_addr:      ifid_rd,
                    load_regfile: ctrl_wd.load_regfile,
                    mem_addr:     ifid_mon_out.mem_addr};

    exmem_mon_in = '{default:     0,
                    inst:         idex_mon_out.inst,
                    pc_rdata:     idex_mon_out.pc_rdata,
                    pc_wdata:     exmem_pc_wdata,
                    rs1_addr:     idex_mon_out.rs1_addr,
                    rs2_addr:     idex_mon_out.rs2_addr,
                    rd_addr:      idex_mon_out.rd_addr,
                    rs1_rdata:    ex_rs1mux_out,
                    rs2_rdata:    ex_rs2mux_out,
                    load_regfile: idex_mon_out.load_regfile,
                    mem_addr:     idex_mon_out.mem_addr};

    memwb_mon_in = '{default:     0,
                    inst:         exmem_mon_out.inst,
                    pc_rdata:     exmem_mon_out.pc_rdata,
                    pc_wdata:     exmem_mon_out.pc_wdata,
                    rs1_addr:     exmem_mon_out.rs1_addr,
                    rs2_addr:     exmem_mon_out.rs2_addr,
                    rd_addr:      exmem_mon_out.rd_addr,
                    rs1_rdata:    exmem_mon_out.rs1_rdata,
                    rs2_rdata:    exmem_mon_out.rs2_rdata,
                    load_regfile: exmem_mon_out.load_regfile,
                    mem_addr:     rvfi_mem_addr,
                    mem_rmask:    rvfi_mem_rmask,
                    mem_wmask:    rvfi_mem_wmask,
                    mem_rdata:    rvfi_mem_rdata,
                    mem_wdata:    rvfi_mem_wdata};

    monitor.inst         = memwb_mon_out.inst;
    monitor.rs1_addr     = memwb_mon_out.rs1_addr;
    monitor.rs2_addr     = memwb_mon_out.rs2_addr;
    monitor.rs1_rdata    = memwb_mon_out.rs1_rdata;
    monitor.rs2_rdata    = memwb_mon_out.rs2_rdata;
    monitor.load_regfile = memwb_mon_out.load_regfile;
    monitor.rd_addr      = memwb_mon_out.rd_addr;
    monitor.rd_wdata     = (memwb_rd) ? regfilemux_out : '0;
    monitor.pc_rdata     = memwb_mon_out.pc_rdata;
    monitor.pc_wdata     = memwb_mon_out.pc_wdata;
    monitor.mem_addr     = memwb_mon_out.mem_addr;
    monitor.mem_rmask    = memwb_mon_out.mem_rmask;
    monitor.mem_wmask    = memwb_mon_out.mem_wmask;
    monitor.mem_rdata    = memwb_mon_out.mem_rdata;
    monitor.mem_wdata    = memwb_mon_out.mem_wdata;
end

monitor_reg ifid_mon  (.clk(clk), .rst(ifid_rst),  .load(load_ifid),  .monitor_i(ifid_mon_in),  .monitor_o(ifid_mon_out));
monitor_reg idex_mon  (.clk(clk), .rst(idex_rst),  .load(load_idex),  .monitor_i(idex_mon_in),  .monitor_o(idex_mon_out));
monitor_reg exmem_mon (.clk(clk), .rst(exmem_rst), .load(load_exmem), .monitor_i(exmem_mon_in), .monitor_o(exmem_mon_out));
monitor_reg memwb_mon (.clk(clk), .rst(memwb_rst), .load(load_memwb), .monitor_i(memwb_mon_in), .monitor_o(memwb_mon_out));

// (* translate_on *)

endmodule : datapath