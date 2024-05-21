// Description: Instruction cache

module icache
    import ariane_pkg::*;
#(
    parameter cache_en = 1'b1)
(
    input   logic   clk_i,
    input   logic   rst_ni,

    // address translation requests
    input   icache_areq_t   areq_i,
    output  icache_arsp_t   areq_o,

    // data requests
    input   icache_dreq_t   dreq_i,
    output  icache_drsp_t   dreq_o,

    // refill port from memory
    input   mem_rsp_t       mreq_i,
    output  mem_req_t       mreq_o
    );

  // functions
  function automatic logic [ICACHE_SET_ASSOC-1:0] icache_way_bin2oh(
      input logic [1:0] in);
    logic [ICACHE_SET_ASSOC-1:0] out;
    out     = '0;
    out[in] = 1'b1;
    return out;
  endfunction

    logic   [riscv::VLEN-1:0]           vaddr_d,vaddr_q;
    logic   [ICACHE_SET_ASSOC-1:0]      cl_hit; // hit from tag compare
    logic                               cache_set_we;     // valid bits write enable


    logic   [ICACHE_TAG_WIDTH-1:0]      cl_tag_d,cl_tag_q;  // cache tag

    logic   [ICACHE_TAG_WIDTH-1:0]      cl_tag_rdata    [ICACHE_SET_ASSOC-1:0];
    logic   [ICACHE_LINE_WIDTH-1:0]     cl_rdata        [ICACHE_SET_ASSOC-1:0];
    //logic   [ICACHE_LINE_WIDTH-1:0][FETCH_WIDTH-1:0]    cl_data;

    logic   [ICACHE_SET_ASSOC-1:0]      tag_req;    // bit enable for valid tag regs
    logic   [ICACHE_SET_ASSOC-1:0]      tag_wdata_vld;  // valid bit to write tag ram
    logic   [ICACHE_SET_ASSOC-1:0]      tag_rdata_vld;  // valid bit coming form valid regs
    logic   [ICACHE_CL_IDX_WIDTH-1:0]   tag_addr;

    logic   [ICACHE_SET_ASSOC-1:0]      cl_req; // bit enable for valid cacheline regs
    logic   [ICACHE_CL_IDX_WIDTH-1:0]   cl_index;   //cache line index
            
    logic   [ICACHE_SET_ASSOC-1:0]      repl_way_oh_d,repl_way_oh_q;    // ways to replace (onehot)
    logic   [$clog2(ICACHE_SET_ASSOC)-1:0]  rnd_way;    // random index for replacement
    //logic                               updata_lfsr;    // shift the LFSR
    
    logic   [ICACHE_TAG_WIDTH:0]        cl_tag_valid_rdata[ICACHE_SET_ASSOC-1:0];

    logic   [$clog2(ICACHE_SET_ASSOC)-1:0]  hit_idx;

    // FSM
    typedef enum logic [2:0] {
        IDLE,
        READ,
        MISS
    } state_e;
    state_e state_d, state_q;

    // extract tag from physical address
    assign cl_tag_d = areq_i.fetch_valid ? areq_i.fetch_paddr[ICACHE_TAG_WIDTH+ICACHE_INDEX_WIDTH-1:ICACHE_INDEX_WIDTH] : cl_tag_q;

    assign vaddr_d = (dreq_o.ready & dreq_i.req) ? dreq_i.vaddr : vaddr_q;
    assign areq_o.fetch_vaddr = vaddr_q;

    assign cl_index = vaddr_d[ICACHE_INDEX_WIDTH-1:ICACHE_OFFSET_WIDTH];
    assign tag_addr = cl_index;

    assign cl_req = cache_set_we ? repl_way_oh_q : '1;
    assign tag_req= cache_set_we ? repl_way_oh_q : '1;
    assign tag_wdata_vld = cache_set_we ? '1 : '0;

    assign repl_way_oh_d = cache_en ? icache_way_bin2oh(rnd_way) : repl_way_oh_q;

    assign mreq_o.paddr = {cl_tag_d,vaddr_q[ICACHE_INDEX_WIDTH-1:3],3'b0};
    assign dreq_o.vaddr = vaddr_q;

    // generate random cacheline index
    lfsr #(
      .LfsrWidth(8),
      .OutWidth ($clog2(ICACHE_SET_ASSOC))
    ) i_lfsr (
      .clk_i (clk_i),
      .rst_ni(rst_ni),
      .en_i  (1'b1),
      .out_o (rnd_way)
    );


    always_comb begin : p_fsm
        state_d = state_q;
        cache_set_we  = 1'b0;

        dreq_o.ready = 1'b0;
        dreq_o.valid = 1'b0;
        areq_o.fetch_req = 1'b0;
        mreq_o.req = 1'b0;

        unique case (state_q)

            IDLE: begin
                if(dreq_i.req) begin
                    dreq_o.ready = 1'b1;
                    state_d = READ;
                end
            end

            READ: begin
                areq_o.fetch_req = 1'b1;
                if(areq_i.fetch_valid) begin
                    if(|cl_hit) begin
                        dreq_o.valid = 1'b1;
                        state_d = IDLE;
                    end else begin
                        state_d = MISS;
                    end
                end
            end

            MISS: begin
                if (mreq_i.ready == 1'b1) begin
                    mreq_o.req = 1'b1;
                    cache_set_we = 1'b1;
                    dreq_o.valid = 1'b1;
                    state_d = IDLE;
                end           
            end
            default: begin
                state_d = IDLE;
            end
        endcase
    end

    // tag comparison, hit generation


    for(genvar i=0; i<ICACHE_SET_ASSOC; i++) begin
        assign cl_hit[i] = (cl_tag_rdata[i] == cl_tag_d) & tag_rdata_vld[i];
        //assign cl_data[i] = cl_rdata[i];
    end

    lzc #(
      .WIDTH(ICACHE_SET_ASSOC)
    ) i_lzc_hit (
      .in_i   (cl_hit),
      .cnt_o  (hit_idx),
      .empty_o()
    );

    always_comb begin
        if (cache_en) begin
            if(state_q == READ && dreq_o.valid == 1'b1) begin
                dreq_o.data = cl_rdata[hit_idx];
            end else if(state_q == MISS && dreq_o.valid == 1'b1) begin
                dreq_o.data = mreq_i.data;
            end
        end else begin
            dreq_o.data = mreq_i.data;
        end
    end

    // memory arrays and regs


    for(genvar i=0; i<ICACHE_SET_ASSOC; i++) begin : gen_sram
        // Tag RAM
        sram #(
            // tag + valid bit
            .DATA_WIDTH(ICACHE_TAG_WIDTH + 1),
            .NUM_WORDS (ICACHE_NUM_WORDS)
        ) tag_sram(
            .clk_i  (clk_i),
            .rst_ni (rst_ni),
            .req_i  (tag_req[i]),
            .we_i   (cache_set_we),
            .addr_i (tag_addr),
            .wdata_i({tag_wdata_vld[i],cl_tag_q}),
            .rdata_o(cl_tag_valid_rdata[i])
        );

        assign cl_tag_rdata[i]  = cl_tag_valid_rdata[i][ICACHE_TAG_WIDTH-1:0];
        assign tag_rdata_vld[i]     = cl_tag_valid_rdata[i][ICACHE_TAG_WIDTH];

        // Data RAM
        sram #(
            .DATA_WIDTH(ICACHE_LINE_WIDTH),
            .NUM_WORDS (ICACHE_NUM_WORDS)
        ) data_sram(
            .clk_i  (clk_i),
            .rst_ni (rst_ni),
            .req_i  (cl_req[i]),
            .we_i   (cache_set_we),
            .addr_i (cl_index),
            .wdata_i(mreq_i.data),
            .rdata_o(cl_rdata[i])
        );
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(~rst_ni) begin
            cl_tag_q    <= '0;
            vaddr_q     <= '0;
            state_q     <= IDLE;
            repl_way_oh_q   <= '0;
        end else begin
            cl_tag_q    <= cl_tag_d;
            vaddr_q     <= vaddr_d;
            state_q     <= state_d;
            repl_way_oh_q   <= repl_way_oh_d;
        end
    end

endmodule
