`timescale 1ns / 1ps

module addSub(
    input clk,
    input en,                // Enable signal
    input [31:0] A,          // Input A (IEEE 754 format)
    input [31:0] B,          // Input B (IEEE 754 format)
    input op,                // Operation: 0 for addition, 1 for subtraction
    output reg [31:0] result // Result (IEEE 754 format)
);

    reg [7:0] expA, expB, expDiff;
    reg [23:0] mantA, mantB;
    reg [24:0] mantSum;
    reg signA, signB, resultSign;
    reg [7:0] resultExp;
    reg [22:0] resultMant;

    always @(posedge clk) begin
        if (en) begin
            // Extract sign, exponent, and mantissa from A and B
            signA = A[31];
            expA = A[30:23];
            mantA = {1'b1, A[22:0]};  // Adding implicit leading 1 for normalized numbers

            signB = B[31];
            expB = B[30:23];
            mantB = {1'b1, B[22:0]};  // Adding implicit leading 1

            if (op == 1)
                signB = ~signB;


            if (signA == signB) begin
                resultSign = signA;
                if (expA >= expB) begin
                    expDiff = expA - expB;
                    mantB = mantB >> expDiff;  // Shift mantissa B to align exponents
                    mantSum = {1'b0, mantA} + {1'b0, mantB};
                    if (mantSum[24] == 0) begin
                        resultExp = expA;          // Result exponent is the larger one
                        resultMant = mantSum[22:0];
                    end
                    else if(mantSum[24] == 1) begin
                        resultExp = expA + 1;
                        resultMant = mantSum[23:1];
                    end
                end
                else begin
                    expDiff = expB - expA;
                    mantA = mantA >> expDiff;  // Shift mantissa B to align exponents
                    mantSum = {1'b0, mantA} + {1'b0, mantB};
                    if (mantSum[24] == 0) begin
                        resultExp = expB;          // Result exponent is the larger one
                        resultMant = mantSum[22:0];
                    end
                    else if(mantSum[24] == 1) begin
                        resultExp = expB + 1;
                        resultMant = mantSum[23:1];
                    end
                end
            end
            else if (signA != signB) begin
                if (expA > expB) begin
                    resultSign = signA;
                    expDiff = expA - expB;
                    mantB = mantB >> expDiff;  // Shift mantissa B to align exponents
                    mantSum = {1'b0, mantA} - {1'b0, mantB};
                    if (mantSum[23:22] == 0) begin
                        resultExp = expA - 2;          // Result exponent is the larger one
                        resultMant = {mantSum[20:0], 2'b0};
                    end
                    else if (mantSum[23] == 0) begin
                        resultExp = expA - 1;          // Result exponent is the larger one
                        resultMant = {mantSum[21:0], 1'b0};
                    end
                    else if(mantSum[23] == 1) begin
                        resultExp = expA;
                        resultMant = mantSum[22:0];
                    end
                end
                else if (expA < expB) begin
                    resultSign = signB;
                    expDiff = expB - expA;
                    mantA = mantA >> expDiff;  // Shift mantissa B to align exponents
                    mantSum = {1'b0, mantB} - {1'b0, mantA};
                    if (mantSum[23:22] == 0) begin
                        resultExp = expB - 2;          // Result exponent is the larger one
                        resultMant = {mantSum[20:0], 2'b0};
                    end
                    else if (mantSum[23] == 0) begin
                        resultExp = expB - 1;          // Result exponent is the larger one
                        resultMant = {mantSum[21:0], 1'b0};
                    end
                    else if(mantSum[23] == 1) begin
                        resultExp = expB;
                        resultMant = mantSum[22:0];
                    end
                end
                else begin
                    if (mantA > mantB) begin
                        resultSign = signA;
                        mantSum = {1'b0, mantA} - {1'b0, mantB};
                        if (mantSum[23:22] == 0) begin
                            resultExp = expA - 2;          // Result exponent is the larger one
                            resultMant = {mantSum[20:0], 2'b0};
                        end
                        else if (mantSum[23] == 0) begin
                            resultExp = expA - 1;          // Result exponent is the larger one
                            resultMant = {mantSum[21:0], 1'b0};
                        end
                        else if(mantSum[23] == 1) begin
                            resultExp = expA;
                            resultMant = mantSum[22:0];
                        end
                    end
                    else if (mantA < mantB) begin
                        resultSign = signB;
                        mantSum = {1'b0, mantB} - {1'b0, mantA};
                        if (mantSum[23:22] == 0) begin
                            resultExp = expB - 2;          // Result exponent is the larger one
                            resultMant = {mantSum[20:0], 2'b0};
                        end
                        else if (mantSum[23] == 0) begin
                            resultExp = expB - 1;          // Result exponent is the larger one
                            resultMant = {mantSum[21:0], 1'b0};
                        end
                        else if(mantSum[23] == 1) begin
                            resultExp = expB;
                            resultMant = mantSum[22:0];
                        end
                    end
                    else begin
                        resultExp = 8'b0;
                        resultSign = signA;
                        resultMant = 23'b0;
                    end
                end
            end
        end
        else begin
            resultSign = 0;
            resultExp = 0;
            resultMant = 0;
        end
    end

    assign result[31] = resultSign;        // Sign bit
    assign result[30:23] = resultExp;      // Exponent
    assign result[22:0] = resultMant[22:0]; // Mantissa (normalized)
    

endmodule