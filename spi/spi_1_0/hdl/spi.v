`timescale 1 ns / 1 ps

module spi #
(
    // Parameters for AXI Slave Bus Interface
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
)
(
    // SPI signals
    output reg cs,               // SPI chip select
    input wire sdin,             // SPI data input (MISO)
    output reg sclk,             // SPI clock
    output reg mosi,             // SPI data output (Master Out Slave In)

    // Ports of AXI Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);

    // Instantiation of AXI Bus Interface S00_AXI
    spi_slave_lite_v1_0_S00_AXI # ( 
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) spi_slave_lite_v1_0_S00_AXI_inst (
        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // User logic for SPI transaction
    // Parameters for SPI timing
    parameter CLOCKS_PER_BIT = 20;      // SPI clock speed parameter
    parameter BITS_PER_TRANSACTION = 16;
    localparam BIT_HALFWAY_CLOCK = CLOCKS_PER_BIT >> 1;

    // Internal SPI state machine registers
    reg [31:0] count0 = 0;
    reg [31:0] count1 = 0;
    reg [15:0] shft = 0;
    reg [15:0] dout = 0;
    reg drdy = 0;  // Data ready signal
    reg [1:0] state = 0;

    // SPI state machine for shifting and data collection
    always @(posedge s00_axi_aclk) begin
        if (!s00_axi_aresetn) begin
            // Reset all state
            state <= 0;
            count0 <= 0;
            count1 <= 0;
            dout <= 0;
            drdy <= 0;
        end else begin
            case (state)
                0: begin  // Waiting for transaction
                    cs <= 1; // Chip select inactive
                    if (count0 == CLOCKS_PER_BIT-1) begin
                        state <= 1;
                        count0 <= 0;
                        cs <= 0; // Chip select active
                    end else begin
                        count0 <= count0 + 1;
                    end
                end
                1: begin  // Shifting data from SPI
                    if (count0 == CLOCKS_PER_BIT-1) begin
                        count0 <= 0;
                        if (count1 == BITS_PER_TRANSACTION-1) begin
                            dout <= shft;  // Store shifted data
                            drdy <= 1;
                            state <= 2;
                            cs <= 1; // Chip select inactive
                        end else begin
                            count1 <= count1 + 1;
                        end
                    end else begin
                        count0 <= count0 + 1;
                        if (count0 == BIT_HALFWAY_CLOCK-1) begin
                            shft <= {shft[14:0], sdin};  // Shift in the SPI data (MISO)
                            mosi <= shft[15]; // Shift out data (MOSI)
                        end
                    end
                end
                2: begin  // Transaction complete
                    if (drdy) begin
                        drdy <= 0;
                        state <= 0;
                        count0 <= 0;
                        count1 <= 0;
                    end
                end
            endcase
        end
    end

    // SPI clock generation
    always @(posedge s00_axi_aclk) begin
        if (state == 1) begin
            sclk <= (count0 < BIT_HALFWAY_CLOCK) ? 0 : 1;  // SPI clock high for half period
        end else begin
            sclk <= 1;  // SPI clock idle high
        end
    end

endmodule
