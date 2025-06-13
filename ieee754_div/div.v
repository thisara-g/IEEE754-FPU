`timescale 1ns / 1ps

module div (
    input clk,
    input en,  // Change enable to en
    input [31:0] A,
    input [31:0] B,
    output zero_division,
    output reg [31:0] result  // Make result a reg to control its output
);

wire [7:0] Exponent;
wire [31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, result_unprotected;
wire [31:0] reciprocal;
wire [31:0] x0, x1, x2, x3;

// Zero division flag
assign zero_division = (B[30:23] == 0) ? 1'b1 : 1'b0;

// ---- Initial value ---- B_Mantissa * (2 ^ -1) * 32 / 17
mult M1(.A({{1'b0, 8'd126, B[22:0]}}), .B(32'h3ff0f0f1), .result(temp1)); // Verified
// Adding 48 / 17 - abs(temp1)
add A1(.A(32'h4034b4b5), .B({1'b1, temp1[30:0]}), .result(x0));

// ---- First Iteration ----
mult M2(.A({{1'b0, 8'd126, B[22:0]}}), .B(x0), .result(temp2));
// +2 - temp2
add A2(.A(32'h40000000), .B({!temp2[31], temp2[30:0]}), .result(temp3));
mult M3(.A(x0), .B(temp3), .result(x1));

// ---- Second Iteration ----
mult M4(.A({1'b0, 8'd126, B[22:0]}), .B(x1), .result(temp4));
add A3(.A(32'h40000000), .B({!temp4[31], temp4[30:0]}), .result(temp5));
mult M5(.A(x1), .B(temp5), .result(x2));

// ---- Third Iteration ----
mult M6(.A({1'b0, 8'd126, B[22:0]}), .B(x2), .result(temp6));
add A4(.A(32'h40000000), .B({!temp6[31], temp6[30:0]}), .result(temp7));
mult M7(.A(x2), .B(temp7), .result(x3));

// ---- Reciprocal: 1 / B ----
assign Exponent = x3[30:23] + 8'd126 - B[30:23];
assign reciprocal = {B[31], Exponent, x3[22:0]};

// ---- Multiplication A * 1 / B ----
mult M8(.A(A), .B(reciprocal), .result(result_unprotected));

// Final result assignment based on en
always @(posedge clk) begin
    if (en) begin
        // If enabled, assign result based on zero_division or invalid A
        result <= ((A[30:23] == 0) || zero_division) ? 32'h00000000 : result_unprotected;
    end else begin
        // If not enabled, result remains unchanged (or set to zero if desired)
        result <= 32'h00000000;
    end
end

endmodule





module mult(
    input [31:0] A,          // Input A (IEEE 754 format)
    input [31:0] B,          // Input B (IEEE 754 format)
    output reg [31:0] result // Result (IEEE 754 format)
);

    reg [7:0] expA, expB;
    reg [23:0] mantA, mantB;
    reg signA, signB, resultSign;
    reg [7:0] resultExp;
    reg [22:0] resultMant;
    reg [47:0] product;
    reg is_nan, is_infinity, is_zero;

    always @(A or B) begin
       
            // Extract sign, exponent, and mantissa from A and B
            signA = A[31];
            expA = A[30:23];
            mantA = {1'b1, A[22:0]};  // Adding implicit leading 1 for normalized numbers

            signB = B[31];
            expB = B[30:23];
            mantB = {1'b1, B[22:0]};  // Adding implicit leading 1

            resultSign = signA ^ signB;

            product = mantA*mantB;

            if (product[47] == 1'b1) begin
                resultExp = expA + expB - 8'd126;
                resultMant = product[46:24]; // Truncate and normalize
            end else begin
                resultExp = expA + expB - 8'd127;
                resultMant = product[45:23]; // No need to normalize
            end
         
            is_nan = ((expA== 8'hFF && A[22:0] != 23'b0) || (expB == 8'hFF && B[22:0] != 23'b0));
            is_infinity = (expA == 8'hFF || expB == 8'hFF);
            is_zero = (A[30:0] == 31'b0 || B[30:0] == 31'b0)||(expA <= 8'd64 && expB <= 8'd64);

            {resultSign, resultExp, resultMant} = 
                                        (is_nan)      ? {1'b0, 8'hFF, 23'h400000} :    // NaN (Assuming 32'hFFC00000 for NaN has sign=0, exp=0xFF, mantissa=0x400000)
                                        (is_zero)     ? 32'h00000000 :                 // Zero
                                        (is_infinity) ? {resultSign, 8'hFF, 23'b0} :   // Infinity
                                                        {resultSign, resultExp, resultMant};  // Normal result
             

        
        
    end

    assign result[31] = resultSign;        // Sign bit
    assign result[30:23] = resultExp;      // Exponent
    assign result[22:0] = resultMant; // Mantissa (normalized)

endmodule



module add(
    input [31:0] A,          // Input A (IEEE 754 format)
    input [31:0] B,          // Input B (IEEE 754 format)
    output reg [31:0] result // Result (IEEE 754 format)
);

    reg [7:0] expA, expB, expDiff;
    reg [23:0] mantA, mantB;
    reg [24:0] mantSum;
    reg signA, signB, resultSign;
    reg [7:0] resultExp;
    reg [22:0] resultMant;

    always @(*) begin
        // Default assignments to avoid latches
        expDiff = 8'b0;
        mantSum = 25'b0;
        resultExp = 8'b0;
        resultMant = 23'b0;
        resultSign = 1'b0;

        // Extract sign, exponent, and mantissa from A and B
        signA = A[31];
        expA = A[30:23];
        mantA = {1'b1, A[22:0]};  // Adding implicit leading 1 for normalized numbers

        signB = B[31];
        expB = B[30:23];
        mantB = {1'b1, B[22:0]};  // Adding implicit leading 1

        if (signA == signB) begin
            resultSign = signA;
            if (expA >= expB) begin
                expDiff = expA - expB;
                mantB = mantB >> expDiff;  // Shift mantissa B to align exponents
                mantSum = {1'b0, mantA} + {1'b0, mantB};
                if (mantSum[24] == 0) begin
                    resultExp = expA;          // Result exponent is the larger one
                    resultMant = mantSum[22:0];
                end else begin
                    resultExp = expA + 1;
                    resultMant = mantSum[23:1];
                end
            end else begin
                expDiff = expB - expA;
                mantA = mantA >> expDiff;  // Shift mantissa A to align exponents
                mantSum = {1'b0, mantA} + {1'b0, mantB};
                if (mantSum[24] == 0) begin
                    resultExp = expB;          // Result exponent is the larger one
                    resultMant = mantSum[22:0];
                end else begin
                    resultExp = expB + 1;
                    resultMant = mantSum[23:1];
                end
            end
        end else begin  // Different signs
            if (expA > expB) begin
                resultSign = signA;
                expDiff = expA - expB;
                mantB = mantB >> expDiff;  // Shift mantissa B to align exponents
                mantSum = {1'b0, mantA} - {1'b0, mantB};
                if (mantSum[23:22] == 0) begin
                    resultExp = expA - 2;   // Adjust result exponent
                    resultMant = {mantSum[20:0], 2'b0};
                end else if (mantSum[23] == 0) begin
                    resultExp = expA - 1;
                    resultMant = {mantSum[21:0], 1'b0};
                end else begin
                    resultExp = expA;
                    resultMant = mantSum[22:0];
                end
            end else if (expA < expB) begin
                resultSign = signB;
                expDiff = expB - expA;
                mantA = mantA >> expDiff;  // Shift mantissa A to align exponents
                mantSum = {1'b0, mantB} - {1'b0, mantA};
                if (mantSum[23:22] == 0) begin
                    resultExp = expB - 2;   // Adjust result exponent
                    resultMant = {mantSum[20:0], 2'b0};
                end else if (mantSum[23] == 0) begin
                    resultExp = expB - 1;
                    resultMant = {mantSum[21:0], 1'b0};
                end else begin
                    resultExp = expB;
                    resultMant = mantSum[22:0];
                end
            end else begin  // expA == expB
                resultExp = expA;
                if (mantA > mantB) begin
                    resultSign = signA;
                    mantSum = {1'b0, mantA} - {1'b0, mantB};
                    resultMant = mantSum[22:0];
                end else if (mantA < mantB) begin
                    resultSign = signB;
                    mantSum = {1'b0, mantB} - {1'b0, mantA};
                    resultMant = mantSum[22:0];
                end else begin
                    resultExp = 8'b0;
                    resultSign = signA;
                    resultMant = 23'b0;
                end
            end
        end
    end

    assign result[31] = resultSign;        // Sign bit
    assign result[30:23] = resultExp;      // Exponent
    assign result[22:0] = resultMant[22:0]; // Mantissa (normalized)

endmodule
