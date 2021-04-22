`include "Wallace_tree_4.v"
`include "RCA.v"
module Multiplier_4xN(A,B,M_OUT);
   parameter n = 8; // 4 * i;
   input [3:0] A;
   input [n-1:0] B;
   output [n+3:0] M_OUT;

   wire [2*n-1:0] IN_M;
   wire [n/4:0] CARRY;
   Wallace_tree_4 tree_first(A,B[3:0],IN_M[7:0]);
   assign M_OUT[3:0] = IN_M[3:0];
   assign CARRY[0] = 0;
   
   genvar i;
   for (i = 1; i < n/4; i = i + 1) begin
      Wallace_tree_4 tree_middle(A,B[i*4+3:i*4], IN_M[i*8+7:i*8]);
      RCA #(.n(4)) rca_middle(.A(IN_M[i*8+3:i*8]),.B(IN_M[i*8-1:i*8-4]),.C_in(CARRY[i-1]),.C_out(CARRY[i]),.SUM(M_OUT[i*4+3:i*4]));
   end
   RCA #(.n(4)) rca_end(.A(IN_M[2*n-1:2*n-4]),.B(4'b0),.C_in(CARRY[n/4-1]),.C_out(CARRY[n/4]),.SUM(M_OUT[n+3:n]));
endmodule   
