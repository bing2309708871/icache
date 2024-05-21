
module sram #(
    parameter DATA_WIDTH = 64,
    parameter NUM_WORDS  = 1024,
    parameter ADDR_WIDTH = $clog2(NUM_WORDS)
)(
   input  logic                          clk_i,
   input  logic                          rst_ni,
   input  logic                          req_i,
   input  logic                          we_i,
   input  logic [ADDR_WIDTH-1:0]  addr_i,
   input  logic [DATA_WIDTH-1:0]         wdata_i,
   output logic [DATA_WIDTH-1:0]         rdata_o
);

    logic   [DATA_WIDTH-1:0] mem_array    [NUM_WORDS-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for(int k=0; k<NUM_WORDS; k++) begin
                mem_array[k] = '0;
            end
        end else if (req_i) begin
            if (!we_i) begin
                rdata_o = mem_array[addr_i];
            end else begin
                mem_array[addr_i] = wdata_i;
            end
        end
    end

endmodule : sram
