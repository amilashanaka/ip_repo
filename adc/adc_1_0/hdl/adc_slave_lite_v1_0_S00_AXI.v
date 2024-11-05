`timescale 1 ns / 1 ps

module adc_slave_lite_v1_0_S00_AXI #
(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 5
)
(
    // AXI Slave Interface
    input wire S_AXI_ACLK,
    input wire S_AXI_ARESETN,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input wire S_AXI_AWVALID,
    output reg S_AXI_AWREADY,
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input wire S_AXI_WVALID,
    output reg S_AXI_WREADY,
    output reg [1 : 0] S_AXI_BRESP,
    output reg S_AXI_BVALID,
    input wire S_AXI_BREADY,
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input wire S_AXI_ARVALID,
    output reg S_AXI_ARREADY,
    output reg [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output reg [1 : 0] S_AXI_RRESP,
    output reg S_AXI_RVALID,
    input wire S_AXI_RREADY
);

    // Internal signals for data storage
    reg [C_S_AXI_DATA_WIDTH-1:0] mem_data;
    reg [C_S_AXI_ADDR_WIDTH-1:0] mem_addr;

    // State for write response
    reg write_resp_done;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 0) begin
            S_AXI_AWREADY <= 0;
            S_AXI_WREADY <= 0;
            S_AXI_BVALID <= 0;
            S_AXI_ARREADY <= 0;
            S_AXI_RVALID <= 0;
            write_resp_done <= 0;
        end else begin
            // Handle write address phase
            if (S_AXI_AWVALID && !S_AXI_AWREADY) begin
                S_AXI_AWREADY <= 1;
                mem_addr <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 0;
            end

            // Handle write data phase
            if (S_AXI_WVALID && S_AXI_AWREADY && !S_AXI_WREADY) begin
                S_AXI_WREADY <= 1;
                if (S_AXI_WSTRB[0]) mem_data[7:0] <= S_AXI_WDATA[7:0];
                if (S_AXI_WSTRB[1]) mem_data[15:8] <= S_AXI_WDATA[15:8];
                if (S_AXI_WSTRB[2]) mem_data[23:16] <= S_AXI_WDATA[23:16];
                if (S_AXI_WSTRB[3]) mem_data[31:24] <= S_AXI_WDATA[31:24];
            end else begin
                S_AXI_WREADY <= 0;
            end

            // Send write response
            if (S_AXI_WREADY && S_AXI_WVALID && !S_AXI_BVALID) begin
                S_AXI_BVALID <= 1;
                S_AXI_BRESP <= 2'b00; // OKAY response
                write_resp_done <= 1;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 0;
                write_resp_done <= 0;
            end

            // Handle read address phase
            if (S_AXI_ARVALID && !S_AXI_ARREADY) begin
                S_AXI_ARREADY <= 1;
                mem_addr <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 0;
            end

            // Handle read data phase
            if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID) begin
                S_AXI_RDATA <= mem_data;
                S_AXI_RRESP <= 2'b00; // OKAY response
                S_AXI_RVALID <= 1;
            end else if (S_AXI_RREADY && S_AXI_RVALID) begin
                S_AXI_RVALID <= 0;
            end
        end
    end
endmodule
