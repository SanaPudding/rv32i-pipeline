module Control
(
    input logic Clk,
    input logic Execute,
    input logic m,
    input logic div,
    input logic sign_diff,
    input logic stall,
    output logic Load,
    output logic Shift,
    output logic Subtract,
    output logic clearAloadB,
    output logic flipsign,
    output logic resp,
    output logic ready,

    //for printing

    input logic [32:0] _opA, _opB,
    input logic [32:0] Aval, Bval
);
//NOTE, We are assumming Execute is active high
enum logic [4:0]
{
    idle,
    load,
    shift,
    load_div,
    sign_switch,
    finish
} state, next_state; 


logic [6:0] count, count_next;

//updates flip flop, current state is the only one
always_ff @ (posedge Clk) begin
    state <= next_state;
    count <= count_next;

end

// Assign outputs based on state
always_comb begin
    next_state  = state;
    count_next = count;
    
    unique case (state)
    
        idle: begin
            if (Execute)
                next_state = load;
            count_next = 7'd33;
        end

        finish: begin
            if(~stall)
                next_state = idle;
        end
            
        load: begin
            count_next = count - 1'd1;
            next_state = shift;
        end
        
        shift : begin
            if(count == 7'd0)
                if(div)
                    next_state = load_div;
                else
                    next_state = finish;
            else
                next_state = load;
        end

        load_div: begin
            if(sign_diff)
                next_state = sign_switch;
            else
                next_state = finish;
        end

        sign_switch : begin
            next_state = finish;
        end
        
        default: next_state = idle;
        
    endcase
    
    Shift = 1'd0;
    Load  = 1'd0;
    Subtract = 1'd0;
    clearAloadB = 1'b0;
    flipsign = 1'd0;
    ready = 1'd0;
    resp = 1'd0;
    
    
    case (state)
    
        load, load_div: begin
            Subtract = !count_next & m;
            Load = 1'd1;
        end

        sign_switch: begin
            flipsign = 1'd1;
        end

        shift: begin
            Subtract = !count & m;
            Shift = 1'b1;
        end

        idle: begin
            Load = 1'd1;
            clearAloadB = 1'd1;
            resp = ~Execute;
        end
        
        finish: begin
            ready = 1'd1;
            resp = 1'd1;
        end

       default: ; 

endcase
end


endmodule