// Description: Cantains all the necessary defines for Ariane in one package

package ariane_pkg;

    localparam int unsigned ICACHE_LINE_WIDTH   = 128;
    localparam int unsigned ICACHE_SET_ASSOC    = 4;
    localparam int unsigned ICACHE_INDEX_WIDTH  = 12;
    localparam int unsigned ICACHE_TAG_WIDTH    = riscv::PLEN - ICACHE_INDEX_WIDTH;

    localparam int unsigned ICACHE_OFFSET_WIDTH = $clog2(ICACHE_LINE_WIDTH/8);
    localparam int unsigned ICACHE_CL_IDX_WIDTH = ICACHE_INDEX_WIDTH - ICACHE_OFFSET_WIDTH;
    localparam int unsigned ICACHE_NUM_WORDS    = 2 ** ICACHE_CL_IDX_WIDTH;

    localparam int unsigned FETCH_WIDTH         = 32;






    typedef struct packed {
        logic                       fetch_valid;    // address translation valid
        logic   [riscv::PLEN-1:0]   fetch_paddr;    // physical address in
    } icache_areq_t;

    typedef struct packed {
        logic                       fetch_req;      // address translation request
        logic   [riscv::VLEN-1:0]   fetch_vaddr;    // virtial address out
    } icache_arsp_t;

    typedef struct packed {
        logic                       req;    // request a new word
        logic   [riscv::VLEN-1:0]   vaddr;
    } icache_dreq_t;

    typedef struct packed {
        logic                       ready;  // icache is ready
        logic                       valid;  // signals a valid read
        logic   [FETCH_WIDTH-1:0]   data;   // cache data
        logic   [riscv::VLEN-1:0]   vaddr;  // virtual address out
    } icache_drsp_t;

    typedef struct packed {
        logic                       req;    // request memory
        logic   [riscv::PLEN-1:0]   paddr;  // physical address
    } mem_req_t;

    typedef struct packed {
        logic                       ready;  // memory is ready;
        logic   [ICACHE_LINE_WIDTH-1:0] data;   // full cache line width
    } mem_rsp_t;

endpackage
