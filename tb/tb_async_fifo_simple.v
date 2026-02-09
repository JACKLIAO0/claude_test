//==============================================================================
// File: tb_async_fifo_simple.v
// Description: Simplified testbench for async FIFO with reliable verification
//==============================================================================

`timescale 1ns/1ps

module tb_async_fifo_simple;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = (1 << ADDR_WIDTH);
    parameter WCLK_PERIOD = 10;
    parameter RCLK_PERIOD = 15;

    reg                     wclk, wrst_n, wen;
    reg  [DATA_WIDTH-1:0]   wdata;
    wire                    wfull;

    reg                     rclk, rrst_n, ren;
    wire [DATA_WIDTH-1:0]   rdata;
    wire                    rempty;

    integer write_count, read_count, error_count;
    reg [DATA_WIDTH-1:0] written_data [0:1023];
    integer wr_idx, rd_idx;

    // DUT
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk(wclk), .wrst_n(wrst_n), .wen(wen), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .ren(ren), .rdata(rdata), .rempty(rempty)
    );

    // Clocks
    initial begin wclk = 0; forever #(WCLK_PERIOD/2) wclk = ~wclk; end
    initial begin rclk = 0; forever #(RCLK_PERIOD/2) rclk = ~rclk; end

    // Waveform
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo_simple);
    end

    // Test
    initial begin
        // Initialize
        wrst_n = 0; rrst_n = 0;
        wen = 0; ren = 0;
        wdata = 0;
        write_count = 0; read_count = 0; error_count = 0;
        wr_idx = 0; rd_idx = 0;

        #100;
        wrst_n = 1; rrst_n = 1;
        #50;

        $display("=== Async FIFO Test ===\n");

        // Test 1: Basic operation
        test_basic();

        // Test 2: Fill and drain
        test_fill_drain();

        // Test 3: Write-heavy then read
        test_burst();

        // Final report
        $display("\n=== FINAL REPORT ===");
        $display("Writes: %0d, Reads: %0d, Errors: %0d", write_count, read_count, error_count);
        if (error_count == 0 && write_count == read_count)
            $display("TEST PASSED!");
        else
            $display("TEST FAILED!");

        #100;
        $finish;
    end

    // Test 1: Basic write and read
    task test_basic;
        integer i;
        begin
            $display("[Test 1] Basic Write/Read");

            // Write one item
            write_item(8'hA5);
            #200; // Wait for sync

            // Read one item
            read_item();
            #100;

            $display("[Test 1] Complete\n");
        end
    endtask

    // Test 2: Fill completely and drain
    task test_fill_drain;
        integer i;
        begin
            $display("[Test 2] Fill and Drain");

            // Fill FIFO
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                write_item(i[7:0]);
            end

            #300; // Wait for sync
            if (!wfull) $display("ERROR: Should be full!");

            // Drain FIFO
            for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
                read_item();
            end

            #300; // Wait for sync
            if (!rempty) $display("ERROR: Should be empty!");

            $display("[Test 2] Complete\n");
        end
    endtask

    // Test 3: Write burst, then read burst
    task test_burst;
        integer i;
        begin
            $display("[Test 3] Burst Operations");

            // Write 50 items
            for (i = 0; i < 50; i = i + 1) begin
                if (wfull) begin
                    #(WCLK_PERIOD*5); // Wait if full
                end
                write_item($random);
                if (i % 3 == 0) #(WCLK_PERIOD*2); // Occasional delay
            end

            #500; // Wait for all writes to sync

            // Read all items
            while (!rempty || (write_count > read_count)) begin
                if (!rempty) begin
                    read_item();
                end
                #(RCLK_PERIOD);
            end

            $display("[Test 3] Complete\n");
        end
    endtask

    // Write one item
    task write_item;
        input [DATA_WIDTH-1:0] data;
        begin
            @(posedge wclk);
            if (!wfull) begin
                wen = 1;
                wdata = data;
                written_data[wr_idx] = data;
                wr_idx = wr_idx + 1;
                write_count = write_count + 1;
                @(posedge wclk);
                wen = 0;
                $display("[%0t] WRITE: 0x%h", $time, data);
            end else begin
                $display("[%0t] FULL: Write blocked", $time);
            end
        end
    endtask

    // Read one item
    task read_item;
        reg [DATA_WIDTH-1:0] expected;
        begin
            @(posedge rclk);
            if (!rempty) begin
                expected = written_data[rd_idx];
                ren = 1;
                #1; // Sample data
                if (rdata !== expected) begin
                    $display("[%0t] ERROR: Expected 0x%h, Got 0x%h", $time, expected, rdata);
                    error_count = error_count + 1;
                end else begin
                    $display("[%0t] READ: 0x%h (OK)", $time, rdata);
                end
                rd_idx = rd_idx + 1;
                read_count = read_count + 1;
                @(posedge rclk);
                ren = 0;
            end
        end
    endtask

endmodule
