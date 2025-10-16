module DMA_cont(
    input           clk,
    input           reset,
    input           dma_request,
    output reg      dma_ack,
    output reg      bus_request,
    input           bus_grant,
    input   [31:0]  src_addr,
    input   [31:0]  dest_addr,
    input   [15:0]  transfer_size,
    input           start_transfer,
    output reg      transfer_done,
    output reg [31:0] addr_out,
    output reg [31:0] data_out,
    input   [31:0]  data_in,
    output reg      mem_read,
    output reg      mem_write,
    input           mem_ready
);

reg [31:0] current_src;
reg [31:0] current_dest;
reg [15:0] remaining;
reg [1:0]  state;
reg        read_complete;
reg [31:0] read_data;

parameter IDLE = 2'b00;
parameter REQUEST_BUS = 2'b01;
parameter READ_MEM = 2'b10;
parameter WRITE_MEM = 2'b11;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= IDLE;
        dma_ack <= 0;
        bus_request <= 0;
        transfer_done <= 0;
        mem_read <= 0;
        mem_write <= 0;
        read_complete <= 0;
        current_src <= 0;
        current_dest <= 0;
        remaining <= 0;
        addr_out <= 0;
        data_out <= 0;
        read_data <= 0;
    end else begin
       
        case (state)
            IDLE: begin
                dma_ack <= 0;
                if (start_transfer && dma_request) begin
                    current_src <= src_addr;
                    current_dest <= dest_addr;
                    remaining <= transfer_size;
                    bus_request <= 1;
                    state <= REQUEST_BUS;
                end
            end
            
            REQUEST_BUS: begin
                if (bus_grant) begin
                    bus_request <= 0;
                    dma_ack <= 1;
                    mem_read <= 1;
                    addr_out <= current_src;
                    state <= READ_MEM;
                end
            end
            
            READ_MEM: begin
                if (mem_ready && mem_read) begin
                    read_data <= data_in;
                    mem_read <= 0;
                    addr_out <= current_dest;
                    data_out <= data_in;
                    mem_write <= 1;
                    state <= WRITE_MEM;
                end else if (!mem_read) begin
                    // Re-assert read if not ready yet
                    mem_read <= 1;
                end
            end
            
            WRITE_MEM: begin
                if (mem_ready && mem_write) begin
                    mem_write <= 0;
                    current_src <= current_src + 4;
                    current_dest <= current_dest + 4;
                    remaining <= remaining - 1;
                    
                    if (remaining == 16'h0001) begin
                        state <= IDLE;
                        transfer_done <= 1;
                        dma_ack <= 0;
                    end else begin
                        mem_read <= 1;
                        addr_out <= current_src + 4;
                        state <= READ_MEM;
                    end
                end else if (!mem_write) begin
                    // Re-assert write if not ready yet
                    mem_write <= 1;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
end

endmodule
