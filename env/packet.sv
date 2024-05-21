// All transaction classes must be extended from the uvm_sequence_item base class.
import ariane_pkg::*;
class packet extends uvm_sequence_item;

  rand icache_dreq_t dreq_i;
  rand logic    [31:0] fetch_data;
    
    `uvm_object_utils_begin(packet)
    `uvm_field_int(dreq_i.req, UVM_ALL_ON)
    `uvm_field_int(dreq_i.vaddr, UVM_ALL_ON)
    `uvm_field_int(fetch_data,UVM_ALL_ON);
    `uvm_object_utils_end

    constraint valid{
        dreq_i.vaddr inside {[0:1024*1024]};
    }
    
    function new(string name = "packet");
      super.new(name);
      `uvm_info("TRACE", $sformatf("%m"), UVM_HIGH);
    endfunction: new

endclass: packet
