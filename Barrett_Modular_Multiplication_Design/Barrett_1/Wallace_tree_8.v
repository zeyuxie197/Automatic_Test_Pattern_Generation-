`timescale 1ns\1ns
module CSA(X,Y,Z,S,C);
input X,Y,Z;
output S,C;

assign S = X ^ Y ^ Z;
assign C = (X & Y) | ((X ^ Y) & Z);  

endmodule

module Wallace_tree_8(A, B, M_OUT);
   input[7:0] A,B;
   output [15:0] M_OUT;
   wire [14:0] P0, P1, P2, P3, P4, P5, P6, P7; 
   
   //partial product generator
   assign P0 = A & {8{B[0]}};
   assign P1 = A & {8{B[1]}};
   assign P2 = A & {8{B[2]}};
   assign P3 = A & {8{B[3]}};
   assign P4 = A & {8{B[4]}};
   assign P5 = A & {8{B[5]}};
   assign P6 = A & {8{B[6]}};
   assign P7 = A & {8{B[7]}}; 

   //first stage
   CSA csa121 (P0[2],P1[1],P2[0],S121,C131);
   CSA csa131 (P0[3],P1[2],P2[1],S131,C141);
   CSA csa141 (P0[4],P1[3],P2[2],S141,C151);
   CSA csa151 (P0[5],P1[4],P2[3],S151,C161);
   CSA csa152 (P3[2],P4[1],P5[0],S152,C162);
   CSA csa161 (P0[6],P1[5],P2[4],S161,C171);
   CSA csa162 (P3[3],P4[2],P5[1],S162,C172);
   CSA csa171 (P0[7],P1[6],P2[5],S171,C181);
   CSA csa172 (P3[4],P4[3],P5[2],S172,C182);
   CSA csa181 (P1[7],P2[6],P3[5],S181,C191);
   CSA csa182 (P4[4],P5[3],P6[2],S182,C192);
   CSA csa191 (P2[7],P3[6],P4[5],S191,C1A1);
   CSA csa192 (P5[4],P6[3],P7[2],S192,C1A2);
   CSA csa1A1 (P3[7],P4[6],P5[5],S1A1,C1B1);
   CSA csa1B1 (P4[7],P5[6],P6[5],S1B1,C1C1);
   CSA csa1C1 (P5[7],P6[6],P7[5],S1C1,C1D1);

   //second stage
   CSA csa231 (P3[0],S131,C131,S231,C241);
   CSA csa241 (P3[1],S141,C141,S241,C251);
   CSA csa251 (S151,S152,C151,S251,C261);
   CSA csa261 (P6[0],S161,S162,S261,C271);
   CSA csa271 (S171,S172,C171,S271,C281);
   CSA csa272 (C172,P6[1],P7[0],S272,C282);
   CSA csa281 (P7[1],S181,S182,S281,C291);
   CSA csa291 (S191,S192,C191,S291,C2A1);
   CSA csa2A1 (P6[4],P7[3],S1A1,S2A1,C2B1);
   CSA csa2B1 (P7[4],S1B1,C1B1,S2B1,C2C1);
   CSA csa2D1 (P6[7],P7[6],C1D1,S2D1,C2E1);
   
   //third stage
   CSA csa341 (P4[0],S241,C241,S341,C351);
   CSA csa361 (C161,C162,S261,S361,C371);
   CSA csa371 (S271,S272,C271,S371,C381);
   CSA csa381 (C181,C182,S281,S381,C391);
   CSA csa391 (C192,S291,C291,S391,C3A1);
   CSA csa3A1 (C1A1,C1A2,S2A1,S3A1,C3B1);
   CSA csa3C1 (S1C1,C1C1,C2C1,S3C1,C3D1);

   //fourth stage
   CSA csa451 (S251,C251,C351,S451,C451);
   CSA csa481 (S381,C281,C282,S481,C481);
   CSA csa4A1 (C2A1,S3A1,C3A1,S4A1,C4A1);
   CSA csa4B1 (S2B1,C2B1,C3B1,S4B1,C4B1);

   //fifth stage






endmodule





// module Barrett(CLK, RST, X, Y_i, M, mu, Z_OUT);
//    parameter n = 1024;
//    parameter m = 4;

//    input [n-1:0] X,M;
//    input [n-1+m:0] Y_i;
//    input [m+4:0] mu;
//    input CLK, RST;
//    output [n:0] Z_OUT;
   
//    wire [n:0] T_i;
// endmodule