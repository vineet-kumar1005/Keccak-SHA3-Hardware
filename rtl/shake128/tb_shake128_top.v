`timescale 1ns / 1ps

module tb_shake128_top;

    reg clk;
    reg rst_n;
    reg start;
    reg [271:0] message_in; // 272 bits (34 bytes)

    wire ready;
    wire done;
    wire [1343:0] hash_out;

    // Instantiate the SHAKE128 Top Module
    shake128_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .message_in(message_in),
        .ready(ready),
        .done(done),
        .hash_out(hash_out)
    );
    
    // ==========================================
    // VCD Dump Generation
    // ==========================================
    initial begin
        $dumpfile("dump.vcd");         // Name of the output VCD file
        $dumpvars(0, tb_shake128_top); // Dump all variables in this module and its submodules
    end

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    // ==========================================
    // Task: Run a Known Answer Test (KAT)
    // ==========================================
    task run_test(input [271:0] test_message, input [8*20:1] test_name); 
    begin
        // Wait for the module to be ready to accept data
        wait(ready == 1'b1);
        
        @(posedge clk);
        #1; // Drive inputs 1ns AFTER the clock edge

        // Apply inputs
        message_in = test_message;
        start = 1'b1;
        
        $display("\n==================================================");
        $display("   TEST CASE: %0s", test_name);
        $display("==================================================");
        $display("INPUT MESSAGE (272 bits / 34 bytes):");
        $display("%x", message_in) ;

        @(posedge clk);
        #1; // Safely de-assert start 1ns AFTER the clock edge
        start = 1'b0; 

        $display("\nHashing... (Permutation running for 24 cycles)");

        // Wait for processing to finish
        wait(done == 1'b1);
        
        @(posedge clk);
        #1; // Safely sample the output AFTER the clock edge
        
        // Display Result
        $display("\nOUTPUT DIGEST (SHAKE128 - 1344 bits / 168 bytes):"); // CHANGED string
        $display("%x", hash_out);
        $display("==================================================\n");
    end
    endtask

    // ==========================================
    // Main Test Sequence
    // ==========================================
    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        message_in = 272'd0;

        // Apply Reset
        #20;
        rst_n = 1;
        #10;

        // Run Test Vectors
        
        // Test 1: 34 bytes of 0x52
        run_test({34{8'h52}}, "34 Bytes of 0x52");

        // Test 2: 34 bytes of 0x00
        run_test({34{8'h00}}, "34 Bytes of 0x00");
        
        // Test 3: 34 bytes of 0xFF
        run_test({34{8'hFF}}, "34 Bytes of 0xFF");

        // End simulation safely
        #50;
        $finish;
    end
    
endmodule