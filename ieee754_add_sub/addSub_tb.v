`timescale 1ns / 1ps

module addSub_tb;

    // Inputs
    reg clk;                  // Clock signal
    reg en;                   // Enable signal
    reg [31:0] A;            // Input A
    reg [31:0] B;            // Input B
    reg op;                  // Operation: 0 for addition, 1 for subtraction

    // Outputs
    wire [31:0] result;      // Result

    // Instantiate the Unit Under Test (UUT)
    addSub uut (
        .clk(clk),
        .en(en),
        .A(A),
        .B(B),
        .op(op),
        .result(result)
    );

    reg [31:0] expected_result; // Register to hold the expected result

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // Toggle clock every 5 ns
    end

    initial begin
        // Initialize Inputs
        en = 1;
        #5;

        // Test Case 1: Add two positive numbers
        op = 0; // 0 for addition
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h40800000; // 4.0 in IEEE 754
        expected_result = 32'h40E00000; // 7.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 2: Subtract a positive number from another
        op = 1; // 1 for subtraction
        A = 32'h40800000; // 4.0 in IEEE 754
        B = 32'h40400000; // 3.0 in IEEE 754
        expected_result = 32'h3F800000; // 1.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 3: Add a positive and a negative number
        op = 0;
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'hC0400000; // -3.0 in IEEE 754
        expected_result = 32'h00000000; // 0.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 4: Subtract two negative numbers
        op = 1;
        A = 32'hC0400000; // -3.0 in IEEE 754
        B = 32'hC0800000; // -4.0 in IEEE 754
        expected_result = 32'h3F800000; // 1.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 5: Add a number and +Infinity
        op = 0;
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h7F800000; // +Infinity in IEEE 754
        expected_result = 32'h7F800000; // +Infinity in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 6: Subtract a number and -Infinity
        op = 1;
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'hFF800000; // -Infinity in IEEE 754
        expected_result = 32'h7F800000; // +Infinity in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 7: Add a positive number and zero
        op = 0;
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h00000000; // 0.0 in IEEE 754
        expected_result = 32'h40400000; // 3.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 8: Subtract zero from a positive number
        op = 1;
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h00000000; // 0.0 in IEEE 754
        expected_result = 32'h40400000; // 3.0 in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 9: Add two denormalized numbers
        op = 0;
        A = 32'h00800000; // Smallest positive normalized number in IEEE 754
        B = 32'h00180000; // Small denormalized number in IEEE 754
        expected_result = 32'h00980000; // Small positive sum in IEEE 754
        #10;
        check_result(A, B, expected_result);

        // Test Case 10: Subtract two denormalized numbers
        op = 1;
        A = 32'h00800000; // Smallest positive normalized number in IEEE 754
        B = 32'h00180000; // Small denormalized number in IEEE 754
        expected_result = 32'h00680000; // Small positive difference in IEEE 754
        #10;
        check_result(A, B, expected_result);

        $finish;
    end

    // Task to check the result and compare with expected value
    task check_result(input [31:0] A, input [31:0] B, input [31:0] expected);
        begin
            $display("A = %h, B = %h, op = %b, result = %h, expected = %h", A, B, op, result, expected);
            if (result === expected) begin
                $display("Test Passed!");
            end else begin
                $display("Test Failed! Expected: %h, Got: %h", expected, result);
            end
        end
    endtask

    initial begin
        $dumpfile("addSub_tb.vcd");
        $dumpvars(0, addSub_tb);
    end

endmodule


