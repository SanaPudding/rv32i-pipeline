module ewb_datapath (
  input clk,
  input rst,
  /* CPU memory data signals */
  input logic  [31:0] mem_address, // already a pmem addr format
  input logic  [255:0] mem_wdata,
  output logic [255:0] mem_rdata,
  /* Physical memory data signals */
  input  logic [255:0] pmem_rdata,
  output logic [255:0] pmem_wdata, 
  output logic [31:0] pmem_address,
  /* Control signals */
  input logic addr_load,
  input logic data_load,
  input logic writing,
  // output logic empty,
  output logic match
);

logic [255:0] data_line_out;
logic [31:0] addr_line_out;

// we keep the data and addr of the data that is waiting to be written back
register #(256) wb_data (clk, rst, data_load, mem_wdata, data_line_out);
register #(32) wb_addr (clk, rst, addr_load, mem_address, addr_line_out);

always_comb begin
  mem_rdata = pmem_rdata; 
  pmem_wdata = data_line_out;
  match = (addr_line_out == mem_address) ? {1'b1} : {1'b0};
  case(writing)
    1'b1: pmem_address = addr_line_out; // write registers to pmem
    default: pmem_address = mem_address;
	endcase
end

endmodule : ewb_datapath