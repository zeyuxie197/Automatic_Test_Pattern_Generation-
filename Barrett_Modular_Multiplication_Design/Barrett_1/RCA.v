module FA(a,b,cin,cout,sum);
input a,b,cin;
output cout,sum;

assign sum = a ^ b ^ cin;
assign cout = (a & b) | ((a ^ b) & cin);  

endmodule

module RCA  (A,B,C_in,C_out, SUM);
   parameter n = 4;
   input [n-1:0] A, B;
   input C_in;
   output reg[n-1:0] SUM;
   output reg C_out;
   wire[n-1:0] S;
   wire[n:0] carry;

   assign carry[0] = C_in;

   genvar i;

   for (i = 0; i < n; i = i + 1) begin
   FA full_adder(A[i], B[i], carry[i], carry[i+1], S[i]);
   end

   always@(*) begin
      C_out = carry[n];
      SUM = S;
   end

endmodule