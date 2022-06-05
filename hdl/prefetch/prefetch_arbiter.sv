module prefetch_arbiter
(
    input clk,
    input rst,

    /* cacheline adapter*/
    // in
    input  logic cline_resp_i,
    input  logic [255:0] cline_rdata_i,
    // out
    output logic [255:0] cline_wdata_o,
    output logic [31:0] cline_address_o,
    output logic cline_read_o,
    output logic cline_write_o,

    /* icache */
    // in
    input  logic [31:0] icache_addr,
    input  logic icache_read,
    // out
    output logic [255:0] arbiter_inst_rdata,
    output logic arbiter_inst_resp,
    
    /* dcache */
    // in
    input  logic [31:0]  dcache_addr,
    input  logic [255:0] dcache_wdata,
    input  logic dcache_read,
    input  logic dcache_write,
    // out
    output logic[255:0] arbiter_data_rdata,
    output logic arbiter_data_resp,

    //prefetching
    input logic arbiter_pf_read,
    input logic [31:0] arbiter_pf_address,
    output logic [255:0] arbiter_pf_rdata,
    output logic arbiter_pf_resp
);

logic icache_req;
logic dcache_req;
assign icache_req = icache_read;
assign dcache_req = dcache_read || dcache_write;

enum bit [1:0] {
    idle,
    icache,
    dcache,
    //add prefetch read 
    prefetch
} state, next_state;

/* State Control Signals */
always_comb begin : state_actions
	/* Defaults */ // icache
    /* cacheline adapter outputs */
    cline_read_o    = '0;
    cline_write_o   = '0;
    cline_address_o = '0;
    cline_wdata_o   = dcache_wdata;
    /* icache outputs */
    arbiter_inst_rdata = cline_rdata_i;
    arbiter_inst_resp  = '0;
    /* dcache outputs */
    arbiter_data_rdata = cline_rdata_i;
    arbiter_data_resp  = '0;

    //prefetching
    arbiter_pf_rdata = '0;
    arbiter_pr_resp = '0;
	
    case(state)
        icache: begin
            /* cacheline adapter outputs */
            cline_read_o    = icache_read;
            cline_address_o = icache_addr;
            
            arbiter_inst_resp  = cline_resp_i;
            arbiter_data_resp  = '0;
		  end
        dcache: begin
            /* cacheline adapter outputs */
            cline_read_o    = dcache_read;
            cline_write_o   = dcache_write;
            cline_address_o = dcache_addr;
            
            arbiter_inst_resp  = '0;
            arbiter_data_resp  = cline_resp_i;
        end
        prefetch: begin
            cline_read_o = 1;
            cline_address_o = arbiter_pf_address;
            arbiter_pf_rdata = arbiter_data_rdata;
            arbiter_pf_resp = arbiter_data_resp;
        end
		  default: ;
	endcase
end

/* Next State Logic */
always_comb begin : next_state_logic
	/* Default state transition */
	next_state = state;
	
	case(state)
		idle: begin
			if (icache_req)      next_state = icache;
			else if (dcache_req) next_state = dcache;
<<<<<<< HEAD:mp4/hdl/prefetch/prefetch_arbiter.sv
            else if (arbiter_pf_read) next_state = prefetch;
			else						next_state = idle;
		end
		icache: if(cline_resp_i) next_state = idle;
		dcache: if(cline_resp_i) next_state = idle;
        prefetch: begin 
            if(cline_resp_i == 1'b0) next_state = prefetch;
            else next_state = idle;
        end 
		// inst_read = 1'b1 in datapath, means an icache_read always requested
=======
			else                 next_state = idle;
		end
		icache: if(cline_resp_i) next_state = idle;
		dcache: if(cline_resp_i) next_state = idle;
>>>>>>> cache_br:mp4/hdl/given_cache/arbiter.sv
	endcase
end

/* Next State Assignment */
always_ff @(posedge clk) begin: next_state_assignment
    if (rst) state <= idle;
    else     state <= next_state;
end

endmodule : prefetch_arbiter