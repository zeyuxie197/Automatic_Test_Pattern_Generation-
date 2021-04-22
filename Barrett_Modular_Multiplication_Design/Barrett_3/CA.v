module CA_1(A,B,C_in,C_out);
   input A,B,C_in;
   output C_out;
   
   assign C_out = (A & B) | ((A ^ B) & C_in);
endmodule

module CA (A,B,C_in,C_out);
   parameter n = 1024;
   input [n-1:0] A;
   input [n-1:0] B;
   input C_in;
   output C_out;
   wire [n:0] carry;

   assign carry[0] = C_in;

   genvar i;

   for (i = 0; i < n; i = i + 1) begin
      CA_1 ca(A[i], B[i], carry[i], carry[i+1]);
   end

   assign C_out = carry[n];
endmodule