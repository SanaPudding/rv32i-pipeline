// reference: https://www.chipverify.com/verilog/verilog-n-bit-shift-register#:~:text=In%20digital%20electronics%2C%20a%20shift,will%20shift%20by%20one%20position.
module shift_reg  #(parameter MSB=8)
(
    input clk,                  // Declare input for clock to all flops in the shift register
    input rst,                  // Declare input to reset the register to a default value
    input d,                    // Declare input for data to the first flop in the shift register
    input en,                   // Declare input for enable to switch the shift register on/off
    output reg [MSB-1:0] out    // Declare output to read out the current value of all flops in this register
);

// This always block will "always" be triggered on the rising edge of clock
// Once it enters the block, it will first check to see if reset is 0 and if yes then reset register
// If no, then check to see if the shift register is enabled
// If no => maintain previous output. If yes, then shift based on the requested direction
always @ (posedge clk)
begin
    if (rst)
        out <= 0;
    else begin
        if (en)
            out <= {out[MSB-2:0], d};
        else
            out <= out;
    end
end

endmodule : shift_reg
