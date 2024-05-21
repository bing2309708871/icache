interface icache_if(input logic clk,input logic rst_n);
import ariane_pkg::*;


    icache_dreq_t   dreq_i;
    icache_drsp_t   dreq_o;
endinterface
