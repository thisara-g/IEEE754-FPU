`timescale 1ns / 1ps

module mult_tb;

    // Inputs
    reg clk;                // Clock signal
    reg en;
    reg [31:0] A;
    reg [31:0] B;
    reg op;

    // Outputs
    wire [31:0] result;

    // Instantiate the Unit Under Test (UUT)
    mult uut (
        .clk(clk),
        .en(en),
        .A(A),
        .B(B),
        .result(result)
    );

    reg [31:0] expected_result; // Register to hold the expected result

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5ns (20ns period)
    end

    initial begin
        // Initialize Inputs
        en = 1;
        #10;
        // Set operation to multiplication

        // Test Case 1: Multiply two positive numbers
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h40000000; // 2.0 in IEEE 754
        expected_result = 32'h40c00000; // 6.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 2: Multiply a positive and a negative number
        A = 32'h4234_851F; // 3.0 in IEEE 754
        B = 32'h427C_851F; // -3.0 in IEEE 754

        expected_result = 32'h4532_10E9; // -9.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 3: Multiply two negative numbers
        A = 32'hC0400000; // -3.0 in IEEE 754
        B = 32'hC0400000; // -3.0 in IEEE 754
        expected_result = 32'h41100000; // 9.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 4: Multiply a number by zero
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h00000000; // 0.0 in IEEE 754
        expected_result = 32'h00000000; // 0.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 5: Multiply a number by one
        A = 32'h40400000; // 3.0 in IEEE 754
        B = 32'h3F800000; // 1.0 in IEEE 754
        expected_result = 32'h40400000; // 3.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 6: Multiply two numbers with the same exponents but different signs
        A = 32'h3F800000; // 1.0 in IEEE 754
        B = 32'hBF800000; // -1.0 in IEEE 754
        expected_result = 32'hBF800000; // -1.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 7: Multiply a number by itself
        A = 32'h40A00000; // 5.0 in IEEE 754
        B = 32'h40A00000; // 5.0 in IEEE 754
        expected_result = 32'h41c80000; // 25.0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        
        // Test Case 1: Multiply two positive numbers
        A = 32'h4234851F; // 45.13 in IEEE 754
        B = 32'h427C851F; // 63.13 in IEEE 754
        expected_result = 32'h453210E9; // 2849.0569 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 2: Multiply a positive and negative number
        A = 32'h4049999A; // 3.15 in IEEE 754
        B = 32'hC1663D71; // -14.39 in IEEE 754
        expected_result = 32'hC2355062; // -45.3285 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 3: Multiply two negative numbers
        A = 32'hC1526666; // -13.15 in IEEE 754
        B = 32'hC240A3D7; // -48.16 in IEEE 754
        expected_result = 32'h441e5374; // 633.304 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

       
        // Test Case 4: Multiply two large numbers
        A = 32'h45800000; // 4096 in IEEE 754
        B = 32'h45800000; // 4096 in IEEE 754
        expected_result = 32'h4B800000; // 16777216 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 5: Multiply two very small numbers
        A = 32'h3ACA62C1; // 0.00154408081 in IEEE 754
        B = 32'h3ACA62C1; // 0.00154408081 in IEEE 754
        expected_result = 32'h361ffffe; // 0.00000238418 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 6: Multiply zero by zero
        A = 32'h00000000; // 0 in IEEE 754
        B = 32'h00000000; // 0 in IEEE 754
        expected_result = 32'h00000000; // 0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 7: Multiply a negative number by zero
        A = 32'hC1526666; // -13.15 in IEEE 754
        B = 32'h00000000; // 0 in IEEE 754
        expected_result = 32'h00000000; // 0 in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 8: Multiply infinity by infinity
        A = 32'h7F800000; // +∞ in IEEE 754
        B = 32'h7F800000; // +∞ in IEEE 754
        expected_result = 32'h7F800000; // +∞ in IEEE 754
        #10;
        check_result(A, B, op, expected_result);

        // Test Case 9: Multiply two denormalized numbers
        A = 32'h00800000; // Small denormalized number in IEEE 754
        B = 32'h00180000; // Small denormalized number in IEEE 754
        expected_result = 32'h00000000; // Result is a denormalized number close to zero
        #10;
        check_result(A, B, op, expected_result);


        // End simulation
        $finish;
    end

    // Task to check the result and compare with expected value
    task check_result(input [31:0] A, input [31:0] B, input op, input [31:0] expected);
        begin
            $display("A = %h, B = %h, op = %b, result = %h, expected = %h", A, B, op, result, expected);
            if (result === expected) begin
                $display("Test Passed!");
            end else begin
                $display("Test Failed! Expected: %h, Got: %h", expected, result);
            end
        end
    endtask

    // VCD Dump for waveform viewing
    initial begin
        $dumpfile("mult_tb.vcd");
        $dumpvars(0, mult_tb);
    end

endmodule
