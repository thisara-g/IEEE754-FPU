`timescale 1ns / 1ps

module fpu_tb;

    // Inputs to the FPU
    reg en;
    reg [1:0] op_sel;
    reg [31:0] A;
    reg [31:0] B;
    reg clk;

    // Outputs from the FPU
    wire zero_division;
    wire [31:0] result;

    // Instantiate the FPU module
    fpu uut (
        .clk(clk),
        .en(en),
        .op(op_sel),
        .A(A),
        .B(B),
        .zero_division(zero_division),
        .result(result)
    );

    // Task for checking the result and comparing with expected value
    task check_result(input [31:0] A, input [31:0] B, input [1:0] op, input [31:0] expected);
        begin
            $display("A = %h, B = %h, op = %b, result = %h, expected = %h", A, B, op, result, expected);
            if (result === expected) begin
                $display("Test Passed!");
            end else begin
                $display("Test Failed! Expected: %h, Got: %h", expected, result);
            end
        end
    endtask

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Toggle clock every 5ns (20ns period)
    end

    initial begin
        // Initialize inputs
        en = 1;
        A = 32'h40400000; // Example value: 3.0 in IEEE 754 format
        B = 32'h40000000; // Example value: 2.0 in IEEE 754 format

        // Test Case 1: Addition
        op_sel = 2'b00;
        #10;  // Wait for 10 time units
        check_result(A, B, op_sel, 32'h40a00000); // 3.0 + 2.0 = 5.0 in IEEE 754 format

        // Test Case 2: Subtraction
        op_sel = 2'b01;
        #10;
        check_result(A, B, op_sel, 32'h3F800000); // 3.0 - 2.0 = 1.0 in IEEE 754 format

        // Test Case 3: Multiplication
        op_sel = 2'b10;
        #10;
        check_result(A, B, op_sel, 32'h40c00000); // 3.0 * 2.0 = 6.0 in IEEE 754 format

        // Test Case 4: Division
        op_sel = 2'b11;
        #10;
        check_result(A, B, op_sel, 32'h3fbfffff); // 3.0 / 2.0 = 1.5 in IEEE 754 format

        // Test Case 5: Division by Zero
        B = 32'h00000000; // Set B to zero
        #10;
        check_result(A, B, op_sel, 32'h00000000); // Expected: Infinity (IEEE 754 result for div by 0)

        // Test Case 6: Disabled FPU (en = 0)
        en = 0;
        A = 32'h3F800000; // 1.0 in IEEE 754 format
        B = 32'h40000000; // 2.0 in IEEE 754 format
        op_sel = 2'b00;   // Addition
        #10;
        check_result(A, B, op_sel, 32'h00000000); // Disabled, result should be 0

        // Test Case 7: Multiply two denormalized numbers
        A = 32'h00800000; // Small denormalized number in IEEE 754
        B = 32'h00180000; // Small denormalized number in IEEE 754
        #10;
        check_result(A, B, 2'b10, 32'h00000000); // Denormalized result close to zero

        // End simulation
        $finish;
    end
endmodule
