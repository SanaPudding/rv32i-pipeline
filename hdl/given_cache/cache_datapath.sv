module cache_datapath # (
  parameter s_index = 3
)
(
  clk,
  mem_byte_enable,
  mem_address,
  mem_wdata,
  mem_rdata,
  pmem_rdata,
  pmem_wdata,
  pmem_address,
  tag_load,
  valid_load,
  dirty_load,
  dirty_in,
  dirty_out,
  hit,
  writing
);
localparam s_offset = 5;
localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;
localparam s_tag = 32 - s_offset - s_index;

input clk;
/* CPU memory data signals */
input logic  [s_mask-1:0]  mem_byte_enable;
input logic  [s_mask-1:0]  mem_address;
input logic  [s_line-1:0] mem_wdata;
output logic [s_line-1:0] mem_rdata;

/* Physical memory data signals */
input  logic [s_line-1:0] pmem_rdata;
output logic [s_line-1:0] pmem_wdata;
output logic [s_mask-1:0]  pmem_address;

/* Control signals */
input logic tag_load;
input logic valid_load;
input logic dirty_load;
input logic dirty_in;
output logic dirty_out;

output logic hit;
input logic [1:0] writing;

logic [s_line-1:0] line_in, line_out;
logic [s_tag-1:0] address_tag, tag_out;
logic [s_index-1:0]  index;
logic [s_mask-1:0] mask;
logic valid_out;

always_comb begin
  address_tag = mem_address[s_offset+s_index+s_tag-1:s_offset+s_index];
  index = mem_address[(s_offset+s_index-1):s_offset];
  hit = valid_out && (tag_out == address_tag);
  pmem_address = (dirty_out) ? {tag_out, index, 5'd0} : mem_address;
  mem_rdata = line_out;
  pmem_wdata = line_out;

  case(writing)
    2'b00: begin // load from memory
      mask = 32'hFFFFFFFF;
      line_in = pmem_rdata;
    end
    2'b01: begin // write from cpu
      mask = mem_byte_enable;
      line_in = mem_wdata;
    end
    default: begin // don't change data
      mask = 32'b0;
      line_in = mem_wdata;
    end
	endcase
end

data_array #(s_index) DM_cache (clk, mask, index, index, line_in, line_out);
array #(.s_index(s_index), .width(s_tag)) tag (clk, tag_load, index, index, address_tag, tag_out);
array #(.s_index(s_index), .width(1)) valid (clk, valid_load, index, index, 1'b1, valid_out);
array #(.s_index(s_index), .width(1)) dirty (clk, dirty_load, index, index, dirty_in, dirty_out);

endmodule : cache_datapath
