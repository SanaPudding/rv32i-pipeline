module testbench();

timeunit 1ns;
timeprecision 1ns;

logic Clk, Run, X, ready;
logic [32:0] opA;
logic [32:0] opB;
logic [32:0] Aval;
logic [32:0] Bval;
logic [65:0] multAns;
assign multAns = {Aval, Bval};
logic div;
Multiplier mul(.*);


always begin : CLOCK_GEN
#5 Clk = ~Clk;
end

initial begin: CLOCK_INIT
    Clk = 0;
end 

initial begin: TEST_VECTORS //testing divide by 0
Run = 1;
div = 0;
opA = 0;
opB = 500;

end
endmodule