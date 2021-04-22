module CSA_F(X,Y,Z,S,C);
   input X,Y,Z;
   output S,C;

   assign S = X ^ Y ^ Z;
   assign C = (X & Y) | ((X ^ Y) & Z);  

endmodule

module CSA_H(X,Y,S,C);
   input X,Y;
   output S,C;

   assign S = X ^ Y;
   assign C = X & Y;  

endmodule

module Wallace_tree_4(A, B, M_OUT);
   input [3:0] A,B;
   output [7:0] M_OUT;
   wire [6:0] P0,P1,P2,P3;
   //partial product generator
   assign P0 = A & {4{B[0]}};
   assign P1 = A & {4{B[1]}};
   assign P2 = A & {4{B[2]}};
   assign P3 = A & {4{B[3]}};
   wire S11,C12,S12,C13,S13,C14,S14,C15,S15,C16,S22,C23,S23,C24,S24,C25,S25,C26,S26,C27;
   wire S33,C34,S34,C35,S35,C36,S36,C37,S37,C38;

   //first stage
   CSA_H csa11 (P0[1],P1[0],S11,C12);
   CSA_F csa12 (P0[2],P1[1],P2[0],S12,C13);
   CSA_F csa13 (P0[3],P1[2],P2[1],S13,C14);
   CSA_F csa14 (P1[3],P2[2],P3[1],S14,C15);
   CSA_H csa15 (P2[3],P3[2],S15,C16);
   
   //second stage
   CSA_H csa22 (S12,C12,S22,C23);
   CSA_F csa23 (P3[0],S13,C13,S23,C24);
   CSA_H csa24 (S14,C14,S24,C25);
   CSA_H csa25 (S15,C15,S25,C26);
   CSA_H csa26 (P3[3],C16,S26,C27);

   //third stage
   CSA_H csa33 (S23,C23,S33,C34);
   CSA_F csa34 (S24,C24,C34,S34,C35);
   CSA_F csa35 (S25,C25,C35,S35,C36);
   CSA_F csa36 (S26,C26,C36,S36,C37);
   CSA_H csa37 (C27,C37,S37,C38);

   //final product
   assign M_OUT[0] = P0[0];
   assign M_OUT[1] = S11;
   assign M_OUT[2] = S22;
   assign M_OUT[3] = S33;
   assign M_OUT[4] = S34;
   assign M_OUT[5] = S35;
   assign M_OUT[6] = S36;
   assign M_OUT[7] = S37;

endmodule