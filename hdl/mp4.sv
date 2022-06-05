import rv32i_types::*;

module mp4(
    input clk,
    input rst,

    output logic mem_read,
    output logic mem_write,
    input  logic [63:0] mem_rdata,
    output logic [63:0] mem_wdata,
    output logic [31:0] mem_addr,
    input mem_resp,

    /*----- RVFI monitor signals -----*/
    output logic halt,
    output logic trap,
    output logic commit,
    output monitor_signals monitor
);

/*****************************************************************************/
localparam s_icache_idx = 4;
localparam s_dcache_idx = 4;
localparam s_scache_idx = 6;
/* L1 caches --> datapath */
logic inst_resp;
logic [31:0] inst_rdata;
logic data_resp;
logic [31:0] data_rdata;
/* datapath --> L1 caches */
logic inst_read;
logic [31:0] inst_addr;
logic data_read;
logic data_write;
logic [3:0] data_mbe;
logic [31:0] data_addr;
logic [31:0] data_wdata;

/* arbiter --> L1 caches */
logic [255:0] arbiter_inst_rdata, arbiter_data_rdata;
logic arbiter_inst_resp, arbiter_data_resp;
/* L1 caches --> arbiter */
logic [31:0] icache_addr, dcache_addr;
logic [255:0] icache_wdata, dcache_wdata;
logic icache_read, icache_write, dcache_read, dcache_write;

/* L2 --> arbiter */
logic [255:0] L2_rdata;
logic L2_resp;
/* arbiter --> L2 */
logic [255:0] arbiter_wdata;
logic [31:0] arbiter_addr;
logic arbiter_read, arbiter_write;

/* ewb --> L2 */
// logic [255:0] ewb_rdata;
// logic ewb_resp;
/* L2 --> ewb */
// logic [255:0] L2_pmem_wdata;
// logic [31:0] L2_pmem_address;
// logic L2_pmem_read, L2_pmem_write;

/* cacheline adapter --> ewb */
logic [255:0] cline_rdata;
logic cline_resp;
/* ewb --> cacheline adapter */
logic [255:0] cline_wdata;
logic [31:0] cline_address;
logic cline_read, cline_write;

datapath datapath(
    .clk        (clk),
    .rst        (rst),

    .inst_read  (inst_read),
    .inst_addr  (inst_addr),
    .inst_resp  (inst_resp),
    .inst_rdata (inst_rdata),

    .data_read  (data_read),
    .data_write (data_write),
    .data_mbe   (data_mbe),
    .data_addr  (data_addr),
    .data_wdata (data_wdata),
    .data_resp  (data_resp),
    .data_rdata (data_rdata),

    .halt       (halt),
    .trap       (trap),
    .commit     (commit),
    .monitor    (monitor)
);

cache #(s_icache_idx) icache(
    .clk (clk),
    /* arbiter */
    // in
    .pmem_resp      (arbiter_inst_resp),
    .pmem_rdata     (arbiter_inst_rdata),
    // out
    .pmem_address   (icache_addr),
    .pmem_wdata     (icache_wdata),
    .pmem_read      (icache_read),
    .pmem_write     (icache_write),
    /* datapath */
    //in
    .mem_read       (inst_read),   
    .mem_write      (1'b0),         // never write
    .mem_byte_enable_cpu (4'd0),    // ever
    .mem_address    (inst_addr),
    .mem_wdata_cpu  (32'd0),        // don't care
    //out
    .mem_resp       (inst_resp),
    .mem_rdata_cpu  (inst_rdata) 
);

cache #(s_dcache_idx) dcache(
    .clk (clk),
    /* arbiter */
    //in
    .pmem_resp      (arbiter_data_resp),
    .pmem_rdata     (arbiter_data_rdata),
    //out
    .pmem_address   (dcache_addr),
    .pmem_wdata     (dcache_wdata),
    .pmem_read      (dcache_read),
    .pmem_write     (dcache_write),
    /* datapath */
    //in
    .mem_read       (data_read),
    .mem_write      (data_write),
    .mem_byte_enable_cpu (data_mbe),
    .mem_address    (data_addr),
    .mem_wdata_cpu  (data_wdata),
    //out
    .mem_resp       (data_resp),
    .mem_rdata_cpu  (data_rdata)
);

arbiter arbiter(
    .clk (clk),
    .rst (rst),
    /* L2 */
    // in from
    .cline_resp_i       (L2_resp),
    .cline_rdata_i      (L2_rdata),   
    // out to
    .cline_wdata_o      (arbiter_wdata),
    .cline_address_o    (arbiter_addr),
    .cline_read_o       (arbiter_read),
    .cline_write_o      (arbiter_write),
    /* icache */
    // in
    .icache_addr        (icache_addr),
    // .icache_wdata       (icache_wdata),
    .icache_read        (icache_read),
    // .icache_write       (icache_write),
    // out
    .arbiter_inst_rdata (arbiter_inst_rdata),
    .arbiter_inst_resp  (arbiter_inst_resp),
    /* dcache */
    // in
    .dcache_addr        (dcache_addr),
    .dcache_wdata       (dcache_wdata),
    .dcache_read        (dcache_read),
    .dcache_write       (dcache_write),
    // out
    .arbiter_data_rdata (arbiter_data_rdata),
    .arbiter_data_resp  (arbiter_data_resp)
);

cache_L2 #(s_scache_idx) scache(
    .clk (clk),
    /* ewb */
    //in from
    .pmem_resp      (cline_resp),
    .pmem_rdata     (cline_rdata),
    //out to
    .pmem_address   (cline_address),
    .pmem_wdata     (cline_wdata),
    .pmem_read      (cline_read),
    .pmem_write     (cline_write),
    /* arbiter */
    //in from
    .mem_read       (arbiter_read),
    .mem_write      (arbiter_write),
    .mem_byte_enable(32'hFFFFFFFF), // only used when get pmem_write from L1, meaning trying to write whole pmem_wdata cacheline into mem, so we want to put all of L1's pmem_wdata, for L2 pov mem_wdata, into L2's cache and behave accordinly
    .mem_address    (arbiter_addr),
    .mem_wdata      (arbiter_wdata),
    //out to
    .mem_resp       (L2_resp),
    .mem_rdata      (L2_rdata)
);

// ewb ewb (
//     .clk (clk),
//     .rst (rst),
//     /* cacheline */
//     //in from
//     .pmem_resp      (cline_resp),
//     .pmem_rdata     (cline_rdata),
//     //out to
//     .pmem_address   (cline_address),
//     .pmem_wdata     (cline_wdata),
//     .pmem_read      (cline_read),
//     .pmem_write     (cline_write),
//     /* L2 */
//     //in from
//     .mem_read       (L2_pmem_read),
//     .mem_write      (L2_pmem_write),
//     .mem_address    (L2_pmem_address),
//     .mem_wdata      (L2_pmem_wdata),
//     //out to
//     .mem_resp       (ewb_resp),
//     .mem_rdata      (ewb_rdata)
// );

cacheline_adaptor cacheline_adaptor(
    .clk     (clk),
    .reset_n (~rst),
    /* L2 */
    // in - from 
    .line_i     (cline_wdata),
    .address_i  (cline_address),
    .read_i     (cline_read),
    .write_i    (cline_write),
    // out - to
    .line_o     (cline_rdata),
    .resp_o     (cline_resp),
    /* phys memory */
    .burst_i    (mem_rdata),
    .burst_o    (mem_wdata),
    .address_o  (mem_addr),
    .read_o     (mem_read),
    .write_o    (mem_write),
    .resp_i     (mem_resp)
);

endmodule : mp4