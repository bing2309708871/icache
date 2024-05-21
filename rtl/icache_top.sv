//Description : cache top

module cache_top import ariane_pkg::*;#()
(
    input   logic   clk_i,
    input   logic   rst_ni,

    // icache interface
    input   icache_dreq_t   dreq_i,
    output  icache_drsp_t   dreq_o
    );

    icache_areq_t   areq_i;
    icache_arsp_t   areq_o;

    mem_req_t       mreq_i;
    mem_rsp_t       mreq_o;

    tlb i_tlb(
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .req_i (areq_o),
        .req_o (areq_i)
    );

    icache  i_icache(
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .areq_i (areq_i),
        .areq_o (areq_o),
        .dreq_i (dreq_i),
        .dreq_o (dreq_o),
        .mreq_i (mreq_o),
        .mreq_o (mreq_i)
    );

    memory i_memory(
        .mreq_i (mreq_i),
        .mreq_o (mreq_o)
    );

endmodule
    


