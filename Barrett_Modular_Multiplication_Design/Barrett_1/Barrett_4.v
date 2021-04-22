`include "Wallace_tree_4.v"
`include "RCA.v"
module Barrett_4 (CLK,RST,CARRY_ADD, CARRY_SUB,X,Y_i,M,mu,Z_OUT);
   parameter n = 1024;
   parameter m = 4;
   

   input CLK,RST,CARRY_ADD,CARRY_SUB;
   input [n-1:0] X;
   input [m-1:0] Y_i;
   input [n-1:0] M;
   input [m+4:0] mu;
   output [n:0] Z_OUT;
   //debug part
   output [n+m-1:0] XY_i;
   output [n+m-1:0] q_M;
   output [3:0] q_i;
   output [n:0] Z_IN;
   output [m+7:0] q_mu;
   output [n+m+3:0] SUB_2;

   wire [n:0] Z_IN;
   wire [3:0] Z_Shift;
   reg [n:0] Z_OUT;
   wire [n+m-1:0] Z_IN_r, XY_i, q_M, ADD_1;
   wire [n+m+3:0] ADD_2,SUB_1,SUB_2, Z_OUT_wire;
   wire [m+7:0] q_mu;
   wire [3:0] q_i;
   wire A_COUT,B_COUT;

   
   

   //Z_IN * r + X * Y_i
   assign Z_IN = Z_OUT;
   assign Z_IN_r = {Z_IN, {m{1'b0}}}; //Z_IN * r;
   Multiplier_4xN #(.n(n)) mul_XY_i(.A(Y_i),.B(X),.M_OUT(XY_i));

   
   RCA #(.n(n+m)) zf_rca(.A(Z_IN_r),.B(XY_i),.C_in(CARRY_ADD), .C_out(A_COUT), .SUM(ADD_1));

   // q_i
   assign Z_Shift = Z_IN[n:n-3];
   Multiplier_4xN #(.n(m+4)) mul_q(.A(Z_Shift),.B(mu),.M_OUT(q_mu));
   assign q_i = {1'b0, q_mu[m+7:m+5]};

   //q_i * M * r
   Multiplier_4xN #(.n(n)) mul_q_M(.A(q_i),.B(M),.M_OUT(q_M));
   assign SUB_1 = {q_M, {m{1'b0}}};

   //Z_i * r + X * Y_i - q_i * M * r
   assign SUB_2 = ~SUB_1;
   assign ADD_2 = {{4{1'b0}}, ADD_1};
   RCA #(.n(n+m+4)) f_rca(.A(SUB_2),.B(ADD_2),.C_in(CARRY_SUB),.C_out(B_COUT),.SUM(Z_OUT_wire));

   always@(posedge CLK, negedge RST) begin
      if (!RST) begin
         Z_OUT <= 0;
      end
      else begin
         Z_OUT <= Z_OUT_wire[n:0];
      end
   end
endmodule