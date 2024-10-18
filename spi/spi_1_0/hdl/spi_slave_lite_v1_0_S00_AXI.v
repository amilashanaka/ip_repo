`timescale 1 ns / 1 ps

module spi_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH    = 32,
    parameter integer C_S_AXI_ADDR_WIDTH    = 4
)
(
    // AXI4LITE signals
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire  S_AXI_AWVALID,
    output wire  S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire  S_AXI_WVALID,
    output wire  S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire  S_AXI_BVALID,
    input wire  S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire  S_AXI_ARVALID,
    output wire  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire  S_AXI_RVALID,
    input wire  S_AXI_RREADY
);

    // AXI4LITE internal signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_awaddr;
    reg   axi_awready;
    reg   axi_wready;
    reg [1 : 0]  axi_bresp;
    reg   axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0]  axi_araddr;
    reg   axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0]  axi_rdata;
    reg [1 : 0]  axi_rresp;
    reg   axi_rvalid;

    // Slave register space
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    integer byte_index;

    // Internal state machine for write
    reg [1:0] state_write;
    localparam [1:0] IDLE_WRITE = 2'b00, WADDR = 2'b01, WDATA = 2'b10;

    // Internal state machine for read
    reg [1:0] state_read;
    localparam [1:0] IDLE_READ = 2'b00, RADDR = 2'b01, RDATA = 2'b10;

    // I/O Connections assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // Write address handshake
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            state_write <= IDLE_WRITE;
        end else begin
            case(state_write)
                IDLE_WRITE: begin
                    if (S_AXI_AWVALID) begin
                        axi_awready <= 1'b1;
                        state_write <= WADDR;
                    end
                end
                WADDR: begin
                    if (S_AXI_AWVALID && S_AXI_AWREADY) begin
                        axi_awaddr <= S_AXI_AWADDR;
                        axi_awready <= 1'b0;
                        state_write <= WDATA;
                    end
                end
                WDATA: begin
                    if (S_AXI_WVALID && S_AXI_WREADY) begin
                        // Write to the corresponding register
                        case (axi_awaddr[ADDR_LSB+1:ADDR_LSB])
                            2'h0: slv_reg0 <= S_AXI_WDATA;
                            2'h1: slv_reg1 <= S_AXI_WDATA;
                            2'h2: slv_reg2 <= S_AXI_WDATA;
                            2'h3: slv_reg3 <= S_AXI_WDATA;
                        endcase
                        state_write <= IDLE_WRITE;
                        axi_bvalid <= 1'b1;
                    end
                end
            endcase
        end
    end

    // Read address handshake
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_rvalid <= 1'b0;
            state_read <= IDLE_READ;
        end else begin
            case(state_read)
                IDLE_READ: begin
                    if (S_AXI_ARVALID) begin
                        axi_arready <= 1'b1;
                        state_read <= RADDR;
                    end
                end
                RADDR: begin
                    if (S_AXI_ARVALID && S_AXI_ARREADY) begin
                        axi_araddr <= S_AXI_ARADDR;
                        axi_arready <= 1'b0;
                        state_read <= RDATA;
                    end
                end
                RDATA: begin
                    axi_rvalid <= 1'b1;
                    case (axi_araddr[ADDR_LSB+1:ADDR_LSB])
                        2'h0: axi_rdata <= slv_reg0;
                        2'h1: axi_rdata <= slv_reg1;
                        2'h2: axi_rdata <= slv_reg2;
                        2'h3: axi_rdata <= slv_reg3;
                    endcase
                    if (S_AXI_RREADY && S_AXI_RVALID) begin
                        axi_rvalid <= 1'b0;
                        state_read <= IDLE_READ;
                    end
                end
            endcase
        end
    end

endmodule
