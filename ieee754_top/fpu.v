`timescale 1ns / 1ps

module fpu (
    input clk,                  // Clock signal
    input en,                   // Enable signal for FPU operations
    input [31:0] A,             // Input A (IEEE 754 format)
    input [31:0] B,             // Input B (IEEE 754 format)
    input [1:0] op,             // Operation: 00 for addition, 01 for subtraction, 10 for multiplication, 11 for division
    output reg [31:0] result,   // Result of FPU operation
    output reg zero_division    // Output signal for zero division error (only for division)
);

    // Internal signals to connect the modules
    wire [31:0] addSubResult;
    wire [31:0] multResult;
    wire [31:0] divResult;
    wire zeroDivError;

    // Instantiate the addSub module (for addition and subtraction)
    addSub addSubUnit (
        .clk(clk),
        .en(en),
        .A(A),
        .B(B),
        .op(op[0]),               // op[0] will determine if it's add or subtract
        .result(addSubResult)
    );

    // Instantiate the mult module (for multiplication)
    mult multUnit (
        .clk(clk),
        .en(en),
        .A(A),
        .B(B),
        .result(multResult)
    );

    // Instantiate the div module (for division)
    div divUnit (
        .clk(clk),
        .en(en),
        .A(A),
        .B(B),
        .zero_division(zeroDivError),  // Capture zero division error
        .result(divResult)
    );

    // Always block to determine the output based on the operation
    always @(posedge clk) begin
        if (en) begin
            case (op)
                2'b00: result <= addSubResult;     // Addition (op = 00)
                2'b01: result <= addSubResult;     // Subtraction (op = 01)
                2'b10: result <= multResult;       // Multiplication (op = 10)
                2'b11: begin                       // Division (op = 11)
                    result <= divResult;           // Division result
                    zero_division <= zeroDivError; // Zero division error
                end
                default: result <= 32'b0;          // Default case to handle unknown op (not required, but safe)
            endcase
        end
        else 
            result <= 32'h00000000;
    end

endmodule
