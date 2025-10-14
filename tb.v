`timescale 1ns/1ps

module DMA_cont_tb;

// Clock and reset
reg clk;
reg reset;

// DMA interface signals
reg dma_request;
wire dma_ack;
wire bus_request;
reg bus_grant;

reg [31:0] src_addr;
reg [31:0] dest_addr;
reg [15:0] transfer_size;
reg start_transfer;
wire transfer_done;

wire [31:0] addr_out;
wire [31:0] data_out;
reg  [31:0] data_in;
wire mem_read;
wire mem_write;
reg  mem_ready;

// Instantiate the DUT (Device Under Test)
DMA_cont uut (
    .clk(clk),
    .reset(reset),
    .dma_request(dma_request),
    .dma_ack(dma_ack),
    .bus_request(bus_request),
    .bus_grant(bus_grant),
    .src_addr(src_addr),
    .dest_addr(dest_addr),
    .transfer_size(transfer_size),
    .start_transfer(start_transfer),
    .transfer_done(transfer_done),
    .addr_out(addr_out),
    .data_out(data_out),
    .data_in(data_in),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_ready(mem_ready)
);

// Generate clock: 10ns period (100MHz)
always #5 clk = ~clk;

// Simple memory model (for demo)
reg [31:0] memory [0:255]; // small dummy memory

// Simulation control
initial begin
    $dumpfile("dma_controller.vcd"); // for GTKWave
    $dumpvars(0, DMA_cont_tb);

    // Initialize
    clk = 0;
    reset = 1;
    dma_request = 0;
    bus_grant = 0;
    start_transfer = 0;
    mem_ready = 0;
    src_addr = 32'h0000_0010;
    dest_addr = 32'h0000_0100;
    transfer_size = 4; // transfer 4 words (4*4 bytes)

    // preload source memory
    memory[4] = 32'hAAAA1111;
    memory[5] = 32'hBBBB2222;
    memory[6] = 32'hCCCC3333;
    memory[7] = 32'hDDDD4444;

    #20 reset = 0;

    // Start DMA transfer
    #10 dma_request = 1;
    start_transfer = 1;

    // After few cycles, grant the bus
    #30 bus_grant = 1;

    // Keep mem_ready active after short delay
    forever begin
        @(posedge clk);
        if (mem_read || mem_write)
            mem_ready <= 1;
        else
            mem_ready <= 0;
    end
end

// Memory read/write simulation
always @(posedge clk) begin
    if (mem_read && mem_ready) begin
        // Simulate read from source
        data_in <= memory[addr_out[9:2]];  // address /4 = index
    end

    if (mem_write && mem_ready) begin
        // Simulate write to destination
        memory[addr_out[9:2]] <= data_out;
        $display("[%0t] WRITE: Addr=%h Data=%h", $time, addr_out, data_out);
    end

    if (transfer_done)
        $display("[%0t] DMA Transfer Completed Successfully!", $time);
end

// Stop simulation
initial begin
    #400;
    $display("Simulation Complete!");
    $finish;
end

endmodule
