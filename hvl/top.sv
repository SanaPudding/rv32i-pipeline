module mp4_tb;
`timescale 1ns/10ps

typedef struct packed {
    logic [31:0] inst;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [31:0] rs1_rdata;
    logic [31:0] rs2_rdata;
    logic        load_regfile;
    logic [4:0]  rd_addr;
    logic [31:0] rd_wdata;
    logic [31:0] pc_rdata;
    logic [31:0] pc_wdata;
    logic [31:0] mem_addr;
    logic [3:0]  mem_rmask;
    logic [3:0]  mem_wmask;
    logic [31:0] mem_rdata;
    logic [31:0] mem_wdata;
} monitor_signals;

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;
logic halt, trap, commit;
monitor_signals monitor;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = commit;    // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = halt;        // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

// The following signals need to be set:
always_comb
begin
// Instruction and trap:
    rvfi.inst = monitor.inst;
    rvfi.trap = trap;

// Regfile:
    rvfi.rs1_addr     = monitor.rs1_addr;
    rvfi.rs2_addr     = monitor.rs2_addr;
    rvfi.rs1_rdata    = monitor.rs1_rdata;
    rvfi.rs2_rdata    = monitor.rs2_rdata;
    rvfi.load_regfile = monitor.load_regfile;
    rvfi.rd_addr      = monitor.rd_addr;
    rvfi.rd_wdata     = monitor.rd_wdata;

// PC:
    rvfi.pc_rdata = monitor.pc_rdata;
    rvfi.pc_wdata = monitor.pc_wdata;

// Memory:
    rvfi.mem_addr  = monitor.mem_addr;
    rvfi.mem_rmask = monitor.mem_rmask;
    rvfi.mem_wmask = monitor.mem_wmask;
    rvfi.mem_rdata = monitor.mem_rdata;
    rvfi.mem_wdata = monitor.mem_wdata;
end

/**************************** End RVFIMON signals ****************************/

// Set this to the proper value
assign itf.registers = '{default: '0};

/*********************** Instantiate your design here ************************/
mp4 dut(
    .clk        (itf.clk        ),
    .rst        (itf.rst        ),

// magic mem ports
    // .inst_read  (itf.inst_read  ),
    // .inst_addr  (itf.inst_addr  ),
    // .inst_resp  (itf.inst_resp  ),
    // .inst_rdata (itf.inst_rdata ),
    // .data_read  (itf.data_read  ),
    // .data_write (itf.data_write ),
    // .data_mbe   (itf.data_mbe   ),
    // .data_addr  (itf.data_addr  ),
    // .data_rdata (itf.data_rdata ),
    // .data_wdata (itf.data_wdata ),
    // .data_resp  (itf.data_resp  ),

// CP2 - burst memory ports:
    .mem_read       (itf.mem_read),
    .mem_write      (itf.mem_write),
    .mem_wdata      (itf.mem_wdata),
    .mem_rdata      (itf.mem_rdata),
    .mem_addr       (itf.mem_addr),
    .mem_resp       (itf.mem_resp),

    .halt    (halt),
    .trap    (trap),
    .commit  (commit),
    .monitor (monitor)
);
/***************************** End Instantiation *****************************/

endmodule