// Description: tlb

module tlb 
    import ariane_pkg::*; #(
    parameter tlb_offset_i = 4'b1111
    )(

    input   logic   clk_i,
    input   logic   rst_ni,

    // icache interface
    input   icache_arsp_t req_i,
    output  icache_areq_t req_o
    );

    always_comb begin
        req_o.fetch_valid = '0;
        req_o.fetch_paddr = '0;

        if(req_i.fetch_req) begin
            req_o.fetch_valid = 1'b1;
            req_o.fetch_paddr = req_i.fetch_vaddr + tlb_offset_i;
        end
    end

endmodule



