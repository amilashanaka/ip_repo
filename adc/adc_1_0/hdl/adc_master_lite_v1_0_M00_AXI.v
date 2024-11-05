`timescale 1 ns / 1 ps

module adc_master_lite_v1_0_M00_AXI #
(
    parameter C_M_START_DATA_VALUE = 32'hAA000000,
    parameter C_M_TARGET_SLAVE_BASE_ADDR = 32'h40000000,
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_M_TRANSACTIONS_NUM = 4
)
(
    // Control signals
    input wire INIT_AXI_TXN,
    output reg ERROR,
    output wire TXN_DONE,
    
    // AXI Clock and Reset
    input wire M_AXI_ACLK,
    input wire M_AXI_ARESETN,

    // AXI Master Interface
    output reg [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
    output reg M_AXI_AWVALID,
    input wire M_AXI_AWREADY,
    output reg [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
    output reg M_AXI_WVALID,
    input wire M_AXI_WREADY,
    input wire [1 : 0] M_AXI_BRESP,
    input wire M_AXI_BVALID,
    output reg M_AXI_BREADY
);

    // State machine states
    reg [1:0] mst_exec_state;
    localparam IDLE = 2'b00, INIT_WRITE = 2'b01, DATA_TRANSFER = 2'b10, ERROR_STATE = 2'b11;

    // Address increment control
    reg [C_M_AXI_ADDR_WIDTH-1 : 0] axi_awaddr = C_M_TARGET_SLAVE_BASE_ADDR;
    
    // Write counter for transactions
    integer write_index = 0;
    
    // AXI transaction initialization
    assign TXN_DONE = (write_index == C_M_TRANSACTIONS_NUM);
    
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 0) begin
            mst_exec_state <= IDLE;
            M_AXI_AWVALID <= 0;
            M_AXI_WVALID <= 0;
            M_AXI_BREADY <= 0;
            ERROR <= 0;
            write_index <= 0;
        end else begin
            case (mst_exec_state)
                IDLE: begin
                    if (INIT_AXI_TXN) begin
                        mst_exec_state <= INIT_WRITE;
                        M_AXI_AWADDR <= axi_awaddr;
                    end
                end

                INIT_WRITE: begin
                    if (!M_AXI_AWVALID && !M_AXI_WVALID && write_index < C_M_TRANSACTIONS_NUM) begin
                        M_AXI_AWVALID <= 1;
                        M_AXI_WDATA <= 0;/* Place PMOD AD1 Data here */;
                        M_AXI_WVALID <= 1;
                        mst_exec_state <= DATA_TRANSFER;
                    end
                end

                DATA_TRANSFER: begin
                    if (M_AXI_AWREADY && M_AXI_WREADY) begin
                        M_AXI_AWVALID <= 0;
                        M_AXI_WVALID <= 0;
                        M_AXI_BREADY <= 1;
                        write_index <= write_index + 1;
                        
                        // Update the address for the next transaction
                        M_AXI_AWADDR <= M_AXI_AWADDR + 4;

                        // Keep the transfer going for continuous streaming
                        if (write_index < C_M_TRANSACTIONS_NUM) begin
                            mst_exec_state <= INIT_WRITE;
                        end else begin
                            mst_exec_state <= IDLE;
                        end
                    end
                end

                ERROR_STATE: begin
                    ERROR <= 1;
                    mst_exec_state <= IDLE;
                end
            endcase
        end
    end

endmodule
