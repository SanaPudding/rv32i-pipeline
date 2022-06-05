import rv32i_types::*;

module monitor_reg
(
    input clk,
    input rst,
    input load,
    input  monitor_signals monitor_i,
    output monitor_signals monitor_o
);

monitor_signals monitor;

assign monitor_o = monitor;

always_ff @(posedge clk)
begin
    if (rst)       monitor <= '0;
    else if (load) monitor <= monitor_i;
    else           monitor <= monitor;
end

endmodule : monitor_reg
