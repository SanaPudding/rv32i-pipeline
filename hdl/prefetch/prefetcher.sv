module prefetcher(
    input clk,
    input rst,
    input logic prefetch_start,
    input logic [31:0] cline_address,
    input logic cache_way,

    output logic [255:0] prefetch_rdata,
    output logic prefetch_ready,
    output logic [31:0] pf_cline_address,
    output logic pf_cache_way,

    output logic pf_read,
    output logic [31:0] pf_address,
    input logic [255:0] pf_rdata,
    input logic pf_resp
);
    //get address from memory, then transfer to arbiter, then back to cache 
    logic busy;
    always_ff @ (posedge clk) begin
        prefetch_ready <= '0;
        if (rst) begin
            //initialize all to 0
            prefetch_ready <= '0;
            prefetch_rdata <= '0;
            pf_read <= '0;
            pf_address <= '0;
            pf_cline_address <= '0;
            busy = '0;
        end
        else if (pf_resp) begin
            prefetch_ready <= '1;
            pf_read <= '0;
            prefetch_rdata <= pf_rdata;
            busy <= '0;
        end
        else if (prefetch_start && ~busy) begin
            
            pf_cline_address <= cline_address + 32'd32; //add 1 block to address to prefetch
            pf_address <= cline_address + 32'd32;
            pf_read <= '1;
            pf_cache_way <= cache_way;
            busy <= '1;
        end
    end
endmodule: prefetcher