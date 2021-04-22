module FA(X,Y,Z,C,S);
   input X,Y,Z;
   output S,C;

   assign S = X ^ Y ^ Z;
   assign C = (X & Y) | ((X ^ Y) & Z);  

endmodule

module RCA_signed (A,B,C_in,C_out,SUM);
   parameter n = 4;
   input signed [n-1:0] A, B;
   input C_in;
   output signed [n-1:0] SUM;
   output C_out;

   wire signed[n-1:0] SUM;
   wire [n:0] carry;
   wire C_out;

   assign carry[0] = C_in;

   genvar i;

   for (i = 0; i < n; i = i + 1) begin
   FA full_adder(A[i], B[i], carry[i], carry[i+1], SUM[i]);
   end
   
   assign C_out = carry[n];

endmodule