
module picorv32_axi_wrapper (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aclk, ASSOCIATED_BUSIF M_AXI, ASSOCIATED_RESET aresetn" *)
    input wire aclk,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME aresetn, POLARITY ACTIVE_LOW" *)
    input wire aresetn,

    output wire trap,

    // AXI4-Lite Master Interface
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWADDR" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME M_AXI, PROTOCOL AXI4LITE, DATA_WIDTH 32, ADDR_WIDTH 32" *)
    output wire [31:0] M_AXI_AWADDR,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWPROT" *)
    output wire [2:0] M_AXI_AWPROT,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWVALID" *)
    output wire M_AXI_AWVALID,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI AWREADY" *)
    input wire M_AXI_AWREADY,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WDATA" *)
    output wire [31:0] M_AXI_WDATA,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WSTRB" *)
    output wire [3:0] M_AXI_WSTRB,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WVALID" *)
    output wire M_AXI_WVALID,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI WREADY" *)
    input wire M_AXI_WREADY,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BRESP" *)
    input wire [1:0] M_AXI_BRESP,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BVALID" *)
    input wire M_AXI_BVALID,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI BREADY" *)
    output wire M_AXI_BREADY,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARADDR" *)
    output wire [31:0] M_AXI_ARADDR,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARPROT" *)
    output wire [2:0] M_AXI_ARPROT,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARVALID" *)
    output wire M_AXI_ARVALID,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI ARREADY" *)
    input wire M_AXI_ARREADY,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RDATA" *)
    input wire [31:0] M_AXI_RDATA,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RRESP" *)
    input wire [1:0] M_AXI_RRESP,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RVALID" *)
    input wire M_AXI_RVALID,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 M_AXI RREADY" *)
    output wire M_AXI_RREADY
);

    picorv32_axi #(
    .STACKADDR(32'h0000_2000)
) u_picorv32_axi (
        .clk    (aclk),
        .resetn (aresetn),
        .trap   (trap),

        .mem_axi_awvalid (M_AXI_AWVALID),
        .mem_axi_awready (M_AXI_AWREADY),
        .mem_axi_awaddr  (M_AXI_AWADDR),
        .mem_axi_awprot  (M_AXI_AWPROT),

        .mem_axi_wvalid  (M_AXI_WVALID),
        .mem_axi_wready  (M_AXI_WREADY),
        .mem_axi_wdata   (M_AXI_WDATA),
        .mem_axi_wstrb   (M_AXI_WSTRB),

        .mem_axi_bvalid  (M_AXI_BVALID),
        .mem_axi_bready  (M_AXI_BREADY),

        .mem_axi_arvalid (M_AXI_ARVALID),
        .mem_axi_arready (M_AXI_ARREADY),
        .mem_axi_araddr  (M_AXI_ARADDR),
        .mem_axi_arprot  (M_AXI_ARPROT),

        .mem_axi_rvalid  (M_AXI_RVALID),
        .mem_axi_rready  (M_AXI_RREADY),
        .mem_axi_rdata   (M_AXI_RDATA),

        // Unused optional coprocessor interface
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'b0),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),

        // Interrupts disabled for this initial design
        .irq (32'b0)
    );

    // PicoRV32 does not consume AXI response codes.
    wire unused_response_codes = ^{M_AXI_BRESP, M_AXI_RRESP};

endmodule
