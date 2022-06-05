module ewb (
  input clk,
  input rst,
  /* Physical memory signals */
  input  logic pmem_resp,
  input  logic [255:0] pmem_rdata,
  output logic [31:0]  pmem_address,
  output logic [255:0] pmem_wdata,
  output logic pmem_read,
  output logic pmem_write,
  /* CPU memory signals */
  input  logic mem_read,
  input  logic mem_write,
  input  logic [31:0] mem_address,
  input  logic [255:0] mem_wdata,
  output logic mem_resp,
  output logic [255:0] mem_rdata
);

logic addr_load, data_load;
logic writing, match;
// logic empty;

ewb_control control(.*);
ewb_datapath datapath(.*);

endmodule : ewb