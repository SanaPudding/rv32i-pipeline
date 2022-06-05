module Multiplier
(
    input logic Clk,
    input logic Run,
    input logic [32:0] opA, opB,
    input logic div,
    input logic stall,
    output logic [32:0] Aval, Bval, 
    output logic resp,
    output logic ready
 );

//control signals 
logic ctrl_load;
logic ctrl_shift;
logic ctrl_sub;
logic ctrl_clearALoadB;

//shift out variables
logic A_R_out;
logic B_R_out;
logic A_L_out;
logic B_L_out;

logic sign_switch;


logic [32:0] Sum;
logic [32:0] opA_Abs;
logic [32:0] opB_Abs;
logic [32:0] _opA;
logic [32:0] _opB;


logic _run;

logic X;

logic [32:0] buffered_opA;
logic [32:0] buffered_opB;

initial begin
    _run = 1'd0;
end

always @(posedge Clk) begin
    _run <= Run;
end

register #(66) opA_buffer
(
    .clk(Clk),
    .load(Run & ~_run),
    .in({opA, opB}),
    .out({buffered_opA, buffered_opB})
);

assign _opA = _run ? buffered_opA : opA;
assign _opB = _run ? buffered_opB : opB;

assign opA_Abs = opA[32] ? -_opA : _opA;
assign opB_Abs = opB[32] ? -_opB : _opB;

/////////////////////////////////////////////////////
//instantiate modules



//instantiate control
Control control_unit
(
    .Clk,
    .Execute(Run),
    .m(B_R_out),
    .div,
    .sign_diff(_opA[32] != _opB[32]),
    .stall,
    .Load(ctrl_load),
    .Shift(ctrl_shift),
    .Subtract(ctrl_sub),
    .clearAloadB(ctrl_clearALoadB),
    .flipsign(sign_switch),
    .resp,
    .ready,
    ._opA, 
    ._opB,
    .Aval, 
    .Bval
);

//instantiate registers
multi_reg regA
(
    .Clk,
    .Reset(ctrl_clearALoadB),  //0 if rst or clearaloadb
    .Load( (~div & ctrl_load) | sign_switch| (div & ~Sum[32] & ctrl_load)), //when ctrl_load is high regA loads
    .D(sign_switch ? -Aval : Sum),
    .ShiftR_In(X), 
    .ShiftR_En(~div & ctrl_shift),
    .ShiftL_In(B_L_out),
    .ShiftL_En(div & ctrl_shift),
    
    .Data_Out(Aval),
    .ShiftR_Out(A_R_out),
    .ShiftL_Out(A_L_out)
);

multi_reg regB
(
    .Clk,
    .Reset(1'd0),
    .Load(ctrl_clearALoadB | (sign_switch & (_opB != 0))), //load from switches when clearALoadB
    .D((sign_switch & (_opB != 0)) ? -Bval : (div ? opA_Abs : _opB)),
    .ShiftR_In(A_R_out), 
    .ShiftR_En(~div & ctrl_shift),
    .ShiftL_In({Aval[31:0], Bval[32]} >= opB_Abs),
    .ShiftL_En(div & ctrl_shift),
    
    .Data_Out(Bval),
    .ShiftR_Out(B_R_out),
    .ShiftL_Out(B_L_out)
);

//instantiate adders
adder mult_adder
(
    .Clk,
    .Switches(div ? opB_Abs : _opA),
    .A(Aval),
    .sub(div | ctrl_sub), 
    .outputEnable(div | (~div & B_R_out)), 
    .x(X),
    .S(Sum)
);

endmodule 