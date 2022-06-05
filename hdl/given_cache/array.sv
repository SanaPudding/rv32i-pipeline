
module array #(parameter width = 1, parameter s_index = 3)
(
  clk,
  load,
  rindex,
  windex,
  datain,
  dataout
);
  localparam num_sets = 2**s_index;
  input clk;
  input logic load;
  input logic [s_index-1:0] rindex;
  input logic [s_index-1:0] windex;
  input logic [width-1:0] datain;
  output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] = '{default: '0};

always_comb begin
  dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk)
begin
    if(load)
        data[windex] <= datain;
end

endmodule : array
