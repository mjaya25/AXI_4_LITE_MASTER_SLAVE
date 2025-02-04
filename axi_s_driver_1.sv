class axi4lite_slave_mem extends uvm_component;
    `uvm_component_utils(axi4lite_slave_mem)

    // AXI4-Lite interface
    virtual axi_interface vif;

    // Memory array
    bit [31:0] mem [int];

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_interface)::get(this, "", "interface_vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface not set for axi4lite_slave_mem")
    endfunction

    // Run phase
    task run_phase(uvm_phase phase);
        vif.arready<=0;
        vif.awready<=0;
        vif.wready<=0;
        vif.rdata<=0;
        vif.rvalid<=0;
        vif.bvalid<=0;
        vif.bresp <= 2'b0;
        fork
        begin
            
        
        forever begin
            // Wait for a valid transaction
            @(posedge vif.awvalid);
            
            if (vif.awvalid) begin
                // Write transaction
                @(posedge vif.clk);
                vif.awready <= 1;
               @(negedge vif.awvalid);
                vif.awready <= 0;
               
                @(posedge vif.wvalid);
                @(posedge vif.clk);
                vif.wready <= 1;
                mem[vif.awaddr[31:0]] = vif.wdata;
                @(negedge vif.wvalid);
                vif.wready <= 0;
               
                vif.bvalid <= 1;
                vif.bresp <= 2'b0;
                wait (vif.bready == 1);
                @(posedge vif.clk);
                vif.bvalid <= 0;
            end
        end
    end
 begin
            
        
        forever begin
            // Wait for a valid transaction
            @(posedge vif.arvalid);
            
            if (vif.arvalid) begin
                // Read transaction
                @(posedge vif.clk);
                vif.arready <= 1;
                @(negedge vif.arvalid);
                vif.arready <= 0;
                vif.rdata <= mem[vif.araddr[31:0]];
                vif.rvalid <= 1;
                wait(vif.rready == 1);
                @(posedge vif.clk);
                vif.rvalid <= 0;
                vif.rdata <= 0;
            end
        end
    end
join
    endtask
endclass