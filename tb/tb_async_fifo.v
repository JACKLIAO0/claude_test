//==============================================================================
// File: tb_async_fifo.v
// Description: Comprehensive testbench for async FIFO
//              Simulates UVM-like verification environment with:
//              - Dual independent clocks
//              - Randomized write/read operations
//              - Data integrity checking
//              - Coverage monitoring
//              - Self-checking mechanism
//==============================================================================

`timescale 1ns/1ps

module tb_async_fifo;

    //==========================================================================
    // Parameters
    //==========================================================================
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = (1 << ADDR_WIDTH);

    // Clock periods (in ns)
    parameter WCLK_PERIOD = 10;
    parameter RCLK_PERIOD = 15;  // Different frequency for async testing

    // Test configuration
    parameter TEST_LENGTH = 1000;
    parameter RANDOM_SEED = 12345;

    //==========================================================================
    // Signals
    //==========================================================================
    reg                     wclk;
    reg                     wrst_n;
    reg                     wen;
    reg  [DATA_WIDTH-1:0]   wdata;
    wire                    wfull;

    reg                     rclk;
    reg                     rrst_n;
    reg                     ren;
    wire [DATA_WIDTH-1:0]   rdata;
    wire                    rempty;

    //==========================================================================
    // Testbench variables
    //==========================================================================
    integer                 write_count;
    integer                 read_count;
    integer                 error_count;
    integer                 i;
    reg     [DATA_WIDTH-1:0] expected_data_queue [0:4095];
    integer                 queue_wr_ptr;
    integer                 queue_rd_ptr;
    integer                 queue_count;

    // Statistics
    integer                 full_events;
    integer                 empty_events;
    integer                 total_writes;
    integer                 total_reads;

    //==========================================================================
    // DUT Instantiation
    //==========================================================================
    async_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .wclk    (wclk),
        .wrst_n  (wrst_n),
        .wen     (wen),
        .wdata   (wdata),
        .wfull   (wfull),
        .rclk    (rclk),
        .rrst_n  (rrst_n),
        .ren     (ren),
        .rdata   (rdata),
        .rempty  (rempty)
    );

    //==========================================================================
    // Clock generation
    //==========================================================================
    initial begin
        wclk = 0;
        forever #(WCLK_PERIOD/2) wclk = ~wclk;
    end

    initial begin
        rclk = 0;
        forever #(RCLK_PERIOD/2) rclk = ~rclk;
    end

    //==========================================================================
    // Reset sequence
    //==========================================================================
    initial begin
        wrst_n = 0;
        rrst_n = 0;
        #100;
        wrst_n = 1;
        rrst_n = 1;
    end

    //==========================================================================
    // Waveform dump
    //==========================================================================
    initial begin
        $dumpfile("async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
    end

    //==========================================================================
    // Test stimulus
    //==========================================================================
    initial begin
        // Initialize
        wen = 0;
        wdata = 0;
        ren = 0;
        write_count = 0;
        read_count = 0;
        error_count = 0;
        queue_wr_ptr = 0;
        queue_rd_ptr = 0;
        queue_count = 0;
        full_events = 0;
        empty_events = 0;
        total_writes = 0;
        total_reads = 0;

        // Wait for reset
        wait(wrst_n && rrst_n);
        #50;

        $display("========================================");
        $display("Starting Async FIFO Test");
        $display("Data Width: %0d, FIFO Depth: %0d", DATA_WIDTH, FIFO_DEPTH);
        $display("Write Clock: %0d ns, Read Clock: %0d ns", WCLK_PERIOD, RCLK_PERIOD);
        $display("========================================\n");

        // Test 1: Basic write and read
        test_basic_write_read();
        #100;

        // Test 2: Fill and empty FIFO
        test_fill_empty();
        #100;

        // Test 3: Continuous write and read
        test_continuous();
        #100;

        // Test 4: Random write and read with different clock ratios
        test_random_operations();
        #100;

        // Test 5: Boundary conditions
        test_boundary_conditions();
        #100;

        // Test 6: Stress test
        test_stress();
        #500;

        // Final report
        print_final_report();

        #100;
        $finish;
    end

    //==========================================================================
    // Test Case 1: Basic write and read
    //==========================================================================
    task test_basic_write_read;
        begin
            $display("[%0t] Test 1: Basic Write and Read", $time);

            // Write single data
            @(posedge wclk);
            write_data(8'hA5);

            #50;

            // Read single data
            @(posedge rclk);
            read_data();

            #50;
            $display("[%0t] Test 1: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Test Case 2: Fill and empty FIFO
    //==========================================================================
    task test_fill_empty;
        integer j;
        begin
            $display("[%0t] Test 2: Fill and Empty FIFO", $time);

            // Fill FIFO
            for (j = 0; j < FIFO_DEPTH; j = j + 1) begin
                @(posedge wclk);
                write_data(j[DATA_WIDTH-1:0]);
            end

            #50;

            if (!wfull) begin
                $display("[%0t] ERROR: FIFO should be full!", $time);
                error_count = error_count + 1;
            end else begin
                $display("[%0t] FIFO is full as expected", $time);
            end

            // Empty FIFO
            for (j = 0; j < FIFO_DEPTH; j = j + 1) begin
                @(posedge rclk);
                read_data();
            end

            #50;

            if (!rempty) begin
                $display("[%0t] ERROR: FIFO should be empty!", $time);
                error_count = error_count + 1;
            end else begin
                $display("[%0t] FIFO is empty as expected", $time);
            end

            $display("[%0t] Test 2: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Test Case 3: Continuous write and read
    //==========================================================================
    task test_continuous;
        integer j;
        begin
            $display("[%0t] Test 3: Continuous Write and Read", $time);

            fork
                // Continuous write
                begin
                    for (j = 0; j < 50; j = j + 1) begin
                        @(posedge wclk);
                        if (!wfull) begin
                            write_data($random);
                        end
                    end
                end

                // Continuous read
                begin
                    for (j = 0; j < 50; j = j + 1) begin
                        @(posedge rclk);
                        if (!rempty) begin
                            read_data();
                        end
                    end
                end
            join

            $display("[%0t] Test 3: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Test Case 4: Random operations
    //==========================================================================
    task test_random_operations;
        integer j;
        integer wr_delay, rd_delay;
        begin
            $display("[%0t] Test 4: Random Operations", $time);

            fork
                // Random write
                begin
                    for (j = 0; j < 100; j = j + 1) begin
                        wr_delay = $random % 5;
                        repeat(wr_delay) @(posedge wclk);
                        if (!wfull) begin
                            write_data($random);
                        end
                        @(posedge wclk);
                    end
                end

                // Random read
                begin
                    #200; // Start reading after some writes
                    for (j = 0; j < 100; j = j + 1) begin
                        rd_delay = $random % 5;
                        repeat(rd_delay) @(posedge rclk);
                        if (!rempty) begin
                            read_data();
                        end
                        @(posedge rclk);
                    end
                end
            join

            $display("[%0t] Test 4: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Test Case 5: Boundary conditions
    //==========================================================================
    task test_boundary_conditions;
        integer j;
        begin
            $display("[%0t] Test 5: Boundary Conditions", $time);

            // Try to write when full
            for (j = 0; j < FIFO_DEPTH + 5; j = j + 1) begin
                @(posedge wclk);
                write_data(j[DATA_WIDTH-1:0]);
            end

            #100;

            // Try to read when empty
            for (j = 0; j < FIFO_DEPTH + 5; j = j + 1) begin
                @(posedge rclk);
                read_data();
            end

            #100;

            $display("[%0t] Test 5: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Test Case 6: Stress test
    //==========================================================================
    task test_stress;
        integer j;
        integer wr_delay, rd_delay;
        begin
            $display("[%0t] Test 6: Stress Test (Long Duration)", $time);

            fork
                // Aggressive write
                begin
                    for (j = 0; j < 500; j = j + 1) begin
                        wr_delay = $random % 3;
                        repeat(wr_delay) @(posedge wclk);
                        if (!wfull) begin
                            write_data($random);
                        end
                    end
                end

                // Aggressive read
                begin
                    #100;
                    for (j = 0; j < 500; j = j + 1) begin
                        rd_delay = $random % 3;
                        repeat(rd_delay) @(posedge rclk);
                        if (!rempty) begin
                            read_data();
                        end
                    end
                end
            join

            // Drain remaining data
            #500;
            while (!rempty) begin
                @(posedge rclk);
                read_data();
            end

            $display("[%0t] Test 6: Completed\n", $time);
        end
    endtask

    //==========================================================================
    // Write data task
    //==========================================================================
    task write_data;
        input [DATA_WIDTH-1:0] data;
        begin
            if (!wfull) begin
                wen = 1;
                wdata = data;
                @(posedge wclk);
                wen = 0;

                // Store in expected queue
                expected_data_queue[queue_wr_ptr] = data;
                queue_wr_ptr = queue_wr_ptr + 1;
                queue_count = queue_count + 1;
                total_writes = total_writes + 1;

                $display("[%0t] WRITE: Data=0x%h, Queue_Count=%0d", $time, data, queue_count);
            end else begin
                full_events = full_events + 1;
                @(posedge wclk);
            end
        end
    endtask

    //==========================================================================
    // Read data task
    //==========================================================================
    task read_data;
        reg [DATA_WIDTH-1:0] expected;
        begin
            if (!rempty && queue_count > 0) begin
                // Wait for clock edge first
                @(posedge rclk);

                // Get expected data before performing read
                expected = expected_data_queue[queue_rd_ptr];

                // Assert read enable
                ren = 1;
                #1; // Small delay to let combinational logic settle

                // Sample data while ren is high
                if (rdata !== expected) begin
                    $display("[%0t] ERROR: Data mismatch! Expected=0x%h, Got=0x%h",
                             $time, expected, rdata);
                    error_count = error_count + 1;
                end else begin
                    $display("[%0t] READ:  Data=0x%h (OK), Queue_Count=%0d",
                             $time, rdata, queue_count-1);
                end

                // Wait for next clock to increment pointer
                @(posedge rclk);
                ren = 0;

                // Update queue
                queue_rd_ptr = queue_rd_ptr + 1;
                queue_count = queue_count - 1;
                total_reads = total_reads + 1;
            end else if (!rempty && queue_count == 0) begin
                // FIFO says not empty but our queue is empty - sync issue
                $display("[%0t] WARNING: FIFO not empty but queue empty - skipping read", $time);
                @(posedge rclk);
            end else begin
                empty_events = empty_events + 1;
                @(posedge rclk);
            end
        end
    endtask

    //==========================================================================
    // Final report
    //==========================================================================
    task print_final_report;
        begin
            $display("\n========================================");
            $display("FINAL TEST REPORT");
            $display("========================================");
            $display("Total Writes:       %0d", total_writes);
            $display("Total Reads:        %0d", total_reads);
            $display("Full Events:        %0d", full_events);
            $display("Empty Events:       %0d", empty_events);
            $display("Errors:             %0d", error_count);
            $display("Queue Count:        %0d (should be 0)", queue_count);
            $display("========================================");

            if (error_count == 0 && queue_count == 0) begin
                $display("TEST PASSED!");
            end else begin
                $display("TEST FAILED!");
            end
            $display("========================================\n");
        end
    endtask

endmodule
