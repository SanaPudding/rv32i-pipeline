module ewb_control (
    input clk,
    input rst,
    /* CPU memory data signals */
    input  logic mem_read,
    input  logic mem_write,
    output logic mem_resp,
    /* Physical memory data signals */
    input  logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write,
    /* Control signals */
    output logic addr_load,
    output logic data_load,
    output logic writing,
    // input logic empty,
    input logic match
);

/* State Enumeration */
enum int unsigned
{   open, 
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    wb
} state, next_state;

/* 
empty, gets a write, goes into holding, goes from w5 to wb
not empty (in holding or writeback), gets a req of the same addr, goes to wb, then puts the new request into the registers (mem_resp gets set at open and the new data gets loaded in), if in wb, finish the wb then go to open.
not empty, gets a write req, go to wb, then open where the next req will be handled.
*/
/* State Control Signals */
always_comb begin : state_actions
    /* Defaults */
    mem_resp = pmem_resp;
    pmem_read = mem_read;
    pmem_write = '0;
    data_load = '0;
    addr_load = '0;
    writing = '0;

	case(state)
    open: begin
        if(mem_write) begin 
            // tell L2 it's been written back, but hold the data in the regs until we can actually write back
            mem_resp = 1'b1;
            data_load = 1'b1;
            addr_load = 1'b1;
            pmem_read = 1'b0;
        end // otherwise, it's a mem_read so phase everything through between L2 and pmem
    end
    h1: begin
        if(match || mem_write) begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;        
        end
    end
    h2: begin
        if(match || mem_write) begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;
        end
    end
    h3: begin
        if(match || mem_write) begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;
        end
    end
    h4: begin
        if(match || mem_write) begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;
        end
    end
    h5: begin
        if(match || mem_write) begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;
        end
    end    
    h6: begin
            pmem_write = 1'b1;
            writing = 1'b1;
            mem_resp = 1'b0;
            pmem_read = 1'b0;
    end          
    wb: begin
        mem_resp = 1'b0;
        pmem_read = 1'b0;
        if(~pmem_resp) begin
            pmem_write = 1'b1;
            writing = 1'b1; //pmem_address = addr_out
        end
    end
	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic
	/* Default state transition */
	next_state = state;
    if (rst) next_state = open;
	else begin
        case(state)
            open: if(mem_write) next_state = h1;
            h1: next_state = (match || mem_write) ? wb : h2;
            h2: next_state = (match || mem_write) ? wb : h3;
            h3: next_state = (match || mem_write) ? wb : h4;
            h4: next_state = (match || mem_write) ? wb : h5;
            h5: next_state = (match || mem_write) ? wb : h6;
            h6: next_state = wb;
            wb: if(pmem_resp) next_state = open;
	    endcase
    end
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
	state <= next_state;
end

endmodule : ewb_control