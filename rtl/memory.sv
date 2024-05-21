
module memory import ariane_pkg::*;#()
(
    //input   logic   clk_i,
    //input   logic   rst_ni,

    // icache interface
    input   mem_req_t   mreq_i,
    output  mem_rsp_t   mreq_o
    );

    parameter MemWords = 1024*1024;

    logic   [31:0] mem_array    [MemWords-1:0];


    initial begin
        automatic bit ok;
        automatic logic [31:0] val;

        for(int k=0; k<MemWords; k++) begin
            ok = randomize(val);
            mem_array[k] = k;
        end
    end

    assign mreq_o.ready = 1'b1;

    always_comb begin
        if (mreq_i.req) begin
            for (int k=0; k<ICACHE_LINE_WIDTH/32; k++) begin
                mreq_o.data[k*32 +:32] = mem_array[mreq_i.paddr+k];
            end
        end
    end

endmodule
