`timescale 1ns / 1ps

module tb_shake256_top;

    reg clk;
    reg rst_n;
    reg start;
    reg [263:0] message_in; // CHANGED: 264 bits (33 bytes)

    wire ready;
    wire done;
    wire [1023:0] hash_out; 

    // Instantiate the SHAKE256 Top Module
    shake256_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .message_in(message_in),
        .ready(ready),
        .done(done),
        .hash_out(hash_out)
    );

    // 100 MHz Clock Generation
    always #5 clk = ~clk;

    // ==========================================
    // Task: Run a Known Answer Test (KAT)
    // ==========================================
    task run_test(input [263:0] test_message, input [8*20:1] test_name); 
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
        $display("INPUT MESSAGE (264 bits / 33 bytes):");
        $display("%x", message_in);

        @(posedge clk);
        #1; // Safely de-assert start 1ns AFTER the clock edge
        start = 1'b0; 

        $display("\nHashing... (Permutation running for 24 cycles)");

        // Wait for processing to finish
        wait(done == 1'b1);
        
        @(posedge clk);
        #1; // Safely sample the output AFTER the clock edge
        
        // Display Result
        $display("\nOUTPUT DIGEST (SHAKE256 - 1088 bits / 136 bytes):"); 
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
        message_in = 264'd0; // CHANGED width

        // Apply Reset
        #20;
        rst_n = 1;
        #10;

        // Run Test Vectors (CHANGED multiplier to 33)
        
        // Test 1: 33 bytes of 0x52
        run_test({33{8'h52}}, "33 Bytes of 0x52");

        // Test 2: 33 bytes of 0x00
        run_test({33{8'h00}}, "33 Bytes of 0x00");
        
        // Test 3: 33 bytes of 0xFF
        run_test({33{8'hFF}}, "33 Bytes of 0xFF");

        // End simulation safely
        #50;
        $finish;
    end
    
endmodule