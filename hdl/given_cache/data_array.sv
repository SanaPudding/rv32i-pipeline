module data_array #(parameter s_index = 3)(
  clk,
  write_en,
  rindex,
  windex,
  datain,
  dataout
);

localparam num_sets = 2**s_index;
localparam s_offset = 5;
localparam s_tag = 32 - s_offset - s_index; 
localparam s_mask   = 2**s_offset;  //32
localparam s_line   = 8*s_mask;     //256
 
input clk;
input logic [s_mask-1:0] write_en;
input logic [s_index-1:0] rindex;
input logic [s_index-1:0] windex;
input logic [s_line-1:0] datain;
output logic [s_line-1:0] dataout;

logic [s_line-1:0] data [num_sets] = '{default: '0};

always_comb begin
  for (int i = 0; i < s_mask; i++) begin
      // select 8 bits starting from 8*i - leave this
      dataout[8*i +: 8] = (write_en[i] & (rindex == windex)) ? datain[8*i +: 8] : data[rindex][8*i +: 8];
  end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < s_mask; i++) begin
		  data[windex][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[windex][8*i +: 8];
    end
end

endmodule : data_array
