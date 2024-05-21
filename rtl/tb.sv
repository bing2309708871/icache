

module tb import ariane_pkg::*; #()();

    timeunit 1ps;
    timeprecision 1ps;

    logic   clk_i;
    logic   rst_ni;

    icache_if    vif(clk_i,rst_ni);

    cache_top   icache_top(
        .clk_i  (clk_i),
        .rst_ni (rst_ni),
        .dreq_i (vif.dreq_i),
        .dreq_o (vif.dreq_o)
    );

    always #(2) clk_i = ~clk_i;


    initial begin
        clk_i = 0;
        rst_ni = 0;
        #10;
        rst_ni = 1;
        #1000;
        //$finish();
    end

endmodule
