module FA(X,Y,Z,S,C);
   input X,Y,Z;
   output S,C;

   assign S = X ^ Y ^ Z;
   assign C = (X & Y) | ((X ^ Y) & Z);  

endmodule

module CSA(X,Y,Z,S,C);
   parameter n;

   input [n-1:0] X,Y,Z;
   output [n-1:0] S;
   output [n-1:0] C;

   wire [n-1:0] IN_C;
   genvar i;
   for (i = 0; i < n; i = i + 1) begin
      FA fa(.X(X[i]),.Y(Y[i]),.Z(Z[i]),.S(S[i]),.C(IN_C[i]));
   end
   assign C = {{IN_C[n-2:0]},{1'b0}};
endmodule
