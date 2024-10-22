`timescale 1 ns / 1 ps

module spi_slave_lite_v1_0_S00_AXI #
(
    // Parameters
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
    // SPI signals
    output reg cs,         // SPI chip select
    input wire sdin,       // SPI data input (MISO)
    output reg sclk,       // SPI clock
    output reg mosi,       // SPI data output (Master Out Slave In)

    // AXI signals
    input wire  S_AXI_ACLK,
    input wire  S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire [2 : 0] S_AXI_AWPROT,
    input wire S_AXI_AWVALID,
    output wire S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output wire S_AXI_WREADY,
    output wire [1 : 0] S_AXI_BRESP,
    output wire S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire [2 : 0] S_AXI_ARPROT,
    input wire S_AXI_ARVALID,
    output wire S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [1 : 0] S_AXI_RRESP,
    output wire S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // Internal AXI signals
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

    // SPI state machine and registers
    parameter CLOCKS_PER_BIT = 20;
    parameter BITS_PER_TRANSACTION = 16;
    localparam BIT_HALFWAY_CLOCK = CLOCKS_PER_BIT >> 1;

    reg [31:0] count0 = 0;
    reg [31:0] count1 = 0;
    reg [15:0] shft = 0;
    reg [15:0] dout = 0;
    reg drdy = 0;
    reg [1:0] state = 0;

    // Slave registers
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0; // To hold SPI data
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;

    // AXI interface assignments
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // AXI write logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_awready <= 0;
            axi_wready <= 0;
            axi_bvalid <= 0;
            slv_reg0 <= 0;
        end else begin
            if (S_AXI_AWVALID && !axi_awready) begin
                axi_awaddr <= S_AXI_AWADDR;
                axi_awready <= 1;
            end else begin
                axi_awready <= 0;
            end

            if (S_AXI_WVALID && axi_awready && !axi_wready) begin
                case (axi_awaddr[3:2])
                    2'b00: slv_reg0 <= S_AXI_WDATA; // Write SPI data
                    2'b01: slv_reg1 <= S_AXI_WDATA;
                    2'b10: slv_reg2 <= S_AXI_WDATA;
                    2'b11: slv_reg3 <= S_AXI_WDATA;
                endcase
                axi_wready <= 1;
                axi_bvalid <= 1;
                axi_bresp <= 2'b00; // OKAY response
            end else begin
                axi_wready <= 0;
                axi_bvalid <= 0;
            end
        end
    end

    // AXI read logic
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            axi_arready <= 0;
            axi_rvalid <= 0;
        end else begin
            if (S_AXI_ARVALID && !axi_arready) begin
                axi_araddr <= S_AXI_ARADDR;
                axi_arready <= 1;
            end else begin
                axi_arready <= 0;
            end

            if (S_AXI_ARREADY && !axi_rvalid) begin
                case (axi_araddr[3:2])
                    2'b00: axi_rdata <= slv_reg0; // Read SPI data
                    2'b01: axi_rdata <= slv_reg1;
                    2'b10: axi_rdata <= slv_reg2;
                    2'b11: axi_rdata <= slv_reg3;
                endcase
                axi_rvalid <= 1;
                axi_rresp <= 2'b00; // OKAY response
            end else begin
                axi_rvalid <= 0;
            end
        end
    end

    // SPI state machine for shifting and data collection
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
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
                            slv_reg0 <= {16'h0000, dout}; // Write SPI data to slv_reg0
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
    always @(posedge S_AXI_ACLK) begin
        if (state == 1) begin
            sclk <= (count0 < BIT_HALFWAY_CLOCK) ? 0 : 1;  // SPI clock high for half period
        end else begin
            sclk <= 1;  // SPI clock idle high
        end
    end

endmodule
