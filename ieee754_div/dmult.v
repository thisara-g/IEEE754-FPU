`timescale 1ns / 1ps

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