/*class axi_m_monitor extends uvm_monitor;
    
    `uvm_component_utils(axi_m_monitor)

    virtual axi_interface vif;

    axi_m_txn txn;
    
    uvm_analysis_port #(axi_m_txn) item_collected_port;

   function new(string name="axi_m_monitor",uvm_component parent = null);
       super.new(name,parent);
       txn = new();
       item_collected_port=new("item_collected_port",this);
   endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
     // txn=axi_m_txn::type_id::create("txn",this);
      if(uvm_config_db#(virtual axi_interface)::get(this, "", "interface_vif",vif) ) begin
        `uvm_info(get_full_name(),"monitor got the interface signals",UVM_NONE);
      end 
      else begin
        `uvm_fatal(get_full_name(),"config db failed in monitor phase");
      end
     `uvm_info(get_full_name(),"this is build_phase of monitor",UVM_NONE);   
    endfunction

    virtual task run_phase(uvm_phase phase);
     bit valid_txn = 0;
        fork 
          //  collect_transactions();
         

      forever begin
          txn = new();

          if(vif.awvalid && vif.awready) begin
              txn.type_trans = WRITE;
              txn.aw_addr = vif.awaddr;
              @(posedge vif.wvalid);
              txn.wdata = vif.wdata;
              @(negedge vif.wvalid);
              valid_txn = 1;
          end
         if(vif.arvalid && vif.arready) begin
              txn.type_trans = READ;
              txn.ar_addr = vif.araddr;
              @(posedge vif.rvalid);
              txn.rdata = vif.rdata;
              @(negedge vif.rvalid);
              valid_txn = 1'b1;
          end

          @(posedge vif.clk);
            if(valid_txn == 'b1) begin
                `uvm_info(get_full_name(),txn.convert2string(),UVM_NONE)
                item_collected_port.write(txn);
            end
            valid_txn = 0;
      end

        join

    endtask 

endclass
*/

class axi_m_monitor extends uvm_monitor;
    `uvm_component_utils(axi_m_monitor)

    virtual axi_interface vif;
    uvm_analysis_port #(axi_m_txn) mon_ap;

    bit [31:0] mem [int]; // Local memory for storing writes

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_ap = new("mon_ap", this);
        if (!uvm_config_db#(virtual axi_interface)::get(this, "", "interface_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for axi_monitor")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            fork
                monitor_write();
                monitor_read();
            join
        end
    endtask

    task monitor_write();
        axi_m_txn txn;
        forever begin
            @(posedge vif.awvalid);
            txn = axi_m_txn::type_id::create("txn");
            txn.type_trans = WRITE;
            txn.aw_addr = vif.awaddr;

            @(posedge vif.wvalid);
            txn.wdata = vif.wdata;
            mem[vif.awaddr] = vif.wdata;
            `uvm_info("","----------------------------------------------------------------------------------------------",UVM_NONE)
            `uvm_info(get_full_name(), $sformatf("Write captured: Addr = %0h, Data = %0h", txn.aw_addr, txn.wdata), UVM_NONE)
            mon_ap.write(txn);
        end
    endtask

    task monitor_read();
        axi_m_txn txn;
        forever begin
            @(posedge vif.arvalid);
            txn = axi_m_txn::type_id::create("txn");
            txn.type_trans = READ;
            txn.ar_addr = vif.araddr;

            @(posedge vif.rvalid);
            txn.rdata = vif.rdata;
            if (mem.exists(vif.araddr) && mem[vif.araddr] != vif.rdata) begin
                `uvm_info("","-------------------------------------------------------------------------------------------",UVM_NONE)
                `uvm_error(get_full_name(), $sformatf("Data mismatch! Addr = %0h, Expected = %0h, Received = %0h", vif.araddr, mem[vif.araddr], vif.rdata))
            end else begin
                `uvm_info("","-------------------------------------------------------------------------------------------",UVM_NONE)
                `uvm_info(get_full_name(), $sformatf("Read captured: Addr = %0h, Data = %0h (Match)", txn.ar_addr, txn.rdata), UVM_NONE)
            end
            mon_ap.write(txn);
        end
    endtask
    
endclass
