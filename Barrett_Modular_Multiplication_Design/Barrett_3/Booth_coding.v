// module Booth_Encoder (X_low, X, X_high, Y, SIGN, PP);
//    parameter n = 1024;
//    input X_low, X, X_high;
//    input [n-1: 0] Y;
//    output SIGN;
//    output [n:0] PP;
//    wire SINGLE, DOUBLE, NEG, NAND1, NAND2, INV1, INV2, INV3;
//    wire [n:0] Y_extend, Y_shift1, AND1, AND2, OR1, PP;
   
//    assign Y_extend = {1'b0, Y};
//    assign Y_shift1 = {Y, 1'b0};

//    //Encoder logic：
//    assign SINGLE = X_low ^ X;
//    assign INV1 = ~X_low;
//    assign INV2 = ~X;
//    assign INV3 = ~X_high;
//    assign NAND1 = ~(X_low & X & INV3);
//    assign NAND2 = ~(INV1 & INV2 & X_high);
//    assign DOUBLE = (~NAND1) | (~NAND2); 
//    assign NEG = X_high;

//    //Selector logic:
//    assign AND1 = Y_shift1 & {(n+1){DOUBLE}};
//    assign AND2 = Y_extend & {(n+1){SINGLE}};
//    assign OR1 = AND1 | AND2;
//    assign PP = OR1 ^ {(n+1){NEG}};
//    assign SIGN = NEG;
// endmodule

module Booth_Encoder (X_low, X, X_high, Y, SIGN, PP);
   parameter n = 1024;
   input X_low, X, X_high;
   input [n-1: 0] Y;
   output SIGN;
   output [n:0] PP;
   wire [n:0] Y_extend, Y_shift1;
   reg [n:0] PP;
   reg SIGN;
   
   assign Y_extend = {1'b0, Y};
   assign Y_shift1 = {Y, 1'b0};

   always @(*) begin
      if (X_high == 1) begin
      if ((X_low == 1) && (X == 1)) begin
         PP = 1;
         SIGN = 1;
      end
      else if ((X_low == 0) && (X == 0)) begin
         PP = ~Y_shift1;
         SIGN = 1;
      end
      else begin
         PP = ~Y_extend;
         SIGN = 1;
      end
   end
   else begin
      if ((X_low == 1) && (X == 1)) begin
         PP = Y_shift1;
         SIGN = 0;
      end
      else if ((X_low == 0) && (X == 0)) begin
         PP = 0;
         SIGN = 0;
      end
      else begin
         PP = Y_extend;
         SIGN = 0;
      end
   end
   end
   
endmodule
