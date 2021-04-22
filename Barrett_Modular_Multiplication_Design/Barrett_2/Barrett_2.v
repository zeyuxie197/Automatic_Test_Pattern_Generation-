`include "CSA.v"
`include "RCA.v"
`include "RCA_signed.v"
module Barrett_2(CLK,RST,X,Y_i,M,mu,Z_OUT,ADD_2,SUB_1,SUB_2,Z_IN_r,q_mu,Z_wire,q_i);
   parameter n = 1024;
   parameter m = 4; 

   input CLK,RST;
   input [n-1:0] X;
   input [m-1:0] Y_i;
   input [n-1:0] M;
   input [m+4:0] mu;
   output [n+m+1:0] Z_OUT;

   //debug part
   output [n+2*m+3:0] ADD_2,SUB_1,SUB_2;
   output [n+2*m+1:0] Z_IN_r;
   output [m+12:0] q_mu;
   output [n+2*m+3:0] Z_wire;
   output [m+1:0] q_i;
   

   reg [n+m+1:0] Z_OUT;

   wire q_OUT,x_OUT,m_OUT,f_OUT;
   //Z_IN * r + X * Y_i type
   wire [n+m+1:0] Z_IN;
   wire [n+2*m+1:0] Z_IN_r;
      //For m = 4:
   wire [n+m-1:0] xP0,xP1,xP2,xP3,xS1,xC1,xS2,xC2;
   wire [n+2*m+3:0] xS3,xC3;
   wire signed [n+2*m+3:0] ADD_2;
   //q_i type for m = 4:
   wire [m+3:0] Z_Shift;
   wire [m+12:0] qP0,qP1,qP2,qP3,qP4,qP5,qP6,qP7,qS1,qC1,qS2,qC2,qS3,qC3,qS4,qC4,qS5,qC5,qS6,qC6;
   wire [m+12:0] q_mu;
   wire [m+3:0] q_i;
   //q_i * M * r type for m = 4:
   wire [n+m-1:0] M_r;
   wire [n+m+7:0] mP0,mP1,mP2,mP3,mP4,mP5,mP6,mP7,mS1,mC1,mS2,mC2,mS3,mC3,mS4,mC4,mS5,mC5,mS6,mC6;
   wire [n+2*m+3:0] SUB_1;
   wire signed [n+2*m+3:0] SUB_2;
   //sum:
   wire signed [n+2*m+4:0] Z_wire;
   
   //Z_IN * r + X * Y_i
   assign Z_IN = Z_OUT;
   assign Z_IN_r = {Z_IN,{m{1'b0}}}; //Z_IN * r;

   //For m = 4:
   assign xP0 = {{(m){1'b0}},{X & {n{Y_i[0]}}}};
   assign xP1 = {{(m-1){1'b0}},{X & {n{Y_i[1]}}},{1'b0}};
   assign xP2 = {{(m-2){1'b0}},{X & {n{Y_i[2]}}},{2{1'b0}}};
   assign xP3 = {{(m-3){1'b0}},{X & {n{Y_i[3]}}},{3{1'b0}}};

   CSA #(.n(n+m)) xcsa1(.X(xP0),.Y(xP1),.Z(xP2),.S(xS1),.C(xC1));
   CSA #(.n(n+m)) xcsa2(.X(xP3),.Y(xS1),.Z(xC1),.S(xS2),.C(xC2)); //X * Y_i compress to 2 (n+m);

   CSA #(.n(n+2*m+4)) xcsa3(.X({{(m+4){1'b0}},xS2}),.Y({{(m+4){1'b0}},xC2}),.Z({{2{1'b0}},Z_IN_r}),.S(xS3),.C(xC3)); //Z_IN * r + X * Y_i compress to 2 (n+m);

   RCA_signed #(.n(n+2*m+4)) xrca1(.A(xS3),.B(xC3),.C_in({1'b0}),.C_out(x_OUT), .SUM(ADD_2)); //Z_IN * r + X * Y_i;

   // assign ADD_2 = ADD_1;
   //q_i
   assign Z_Shift = Z_IN[n+m+1:n-2]; //m+4 bits;
   // for m = 4:
   assign qP0 = {{8{1'b0}},{mu & {(m+5){Z_Shift[0]}}}};
   assign qP1 = {{7{1'b0}},{mu & {(m+5){Z_Shift[1]}}},{1'b0}};
   assign qP2 = {{6{1'b0}},{mu & {(m+5){Z_Shift[2]}}},{2{1'b0}}};
   assign qP3 = {{5{1'b0}},{mu & {(m+5){Z_Shift[3]}}},{3{1'b0}}};
   assign qP4 = {{4{1'b0}},{mu & {(m+5){Z_Shift[4]}}},{4{1'b0}}};
   assign qP5 = {{3{1'b0}},{mu & {(m+5){Z_Shift[5]}}},{5{1'b0}}};
   assign qP6 = {{2{1'b0}},{mu & {(m+5){Z_Shift[6]}}},{6{1'b0}}};
   assign qP7 = {{1{1'b0}},{mu & {(m+5){Z_Shift[7]}}},{7{1'b0}}};

   CSA #(.n(m+13)) qcsa1(.X(qP0),.Y(qP1),.Z(qP2),.S(qS1),.C(qC1));
   CSA #(.n(m+13)) qcsa2(.X(qP3),.Y(qP4),.Z(qP5),.S(qS2),.C(qC2));

   CSA #(.n(m+13)) qcsa3(.X(qP6),.Y(qP7),.Z(qS1),.S(qS3),.C(qC3));
   CSA #(.n(m+13)) qcsa4(.X(qS2),.Y(qC2),.Z(qC1),.S(qS4),.C(qC4));

   CSA #(.n(m+13)) qcsa5(.X(qS3),.Y(qC3),.Z(qS4),.S(qS5),.C(qC5));

   CSA #(.n(m+13)) qcsa6(.X(qC4),.Y(qS5),.Z(qC5),.S(qS6),.C(qC6)); //q_i compress to 2 (m+9);

   RCA #(.n(m+13)) qrca1(.A(qS6),.B(qC6),.C_in({1'b0}),.C_out(q_OUT), .SUM(q_mu));

   assign q_i = q_mu[m+12:9]; //m + 4 bits;

   //q_i * M * r
   assign M_r = {M,{m{1'b0}}};
   //for m = 4:
   assign mP0 = {{8{1'b0}},{M_r & {(n+m){q_i[0]}}}};
   assign mP1 = {{7{1'b0}},{M_r & {(n+m){q_i[1]}}},{1{1'b0}}};
   assign mP2 = {{6{1'b0}},{M_r & {(n+m){q_i[2]}}},{2{1'b0}}};
   assign mP3 = {{5{1'b0}},{M_r & {(n+m){q_i[3]}}},{3{1'b0}}};
   assign mP4 = {{4{1'b0}},{M_r & {(n+m){q_i[4]}}},{4{1'b0}}};
   assign mP5 = {{3{1'b0}},{M_r & {(n+m){q_i[5]}}},{5{1'b0}}};
   assign mP6 = {{2{1'b0}},{M_r & {(n+m){q_i[6]}}},{6{1'b0}}};
   assign mP7 = {{1{1'b0}},{M_r & {(n+m){q_i[7]}}},{7{1'b0}}};

   CSA #(.n(n+m+8)) mcsa1(.X(mP0),.Y(mP1),.Z(mP2),.S(mS1),.C(mC1));
   CSA #(.n(n+m+8)) mcsa2(.X(mP3),.Y(mP4),.Z(mP5),.S(mS2),.C(mC2));

   CSA #(.n(n+m+8)) mcsa3(.X(mP6),.Y(mP7),.Z(mS1),.S(mS3),.C(mC3));
   CSA #(.n(n+m+8)) mcsa4(.X(mS2),.Y(mC2),.Z(mC1),.S(mS4),.C(mC4));

   CSA #(.n(n+m+8)) mcsa5(.X(mS3),.Y(mC3),.Z(mS4),.S(mS5),.C(mC5));

   CSA #(.n(n+m+8)) mcsa6(.X(mC4),.Y(mS5),.Z(mC5),.S(mS6),.C(mC6));

   RCA #(.n(n+m+8)) mrca5(.A(mS6),.B(mC6),.C_in({1'b0}),.C_out(m_OUT), .SUM(SUB_1[n+m+7:0]));

   // assign SUB_1[n+2*m+3:n+m+8] = 0; //sign bit;
   assign SUB_2 = ~SUB_1; //convert to negative number;
   
   //Z_IN * r + X * Y_i - q_i * M * r
   RCA_signed #(.n(n+2*m+5)) frca1(.A({{1'b1},SUB_2}),.B({{1'b0},ADD_2}),.C_in({1'b1}),.C_out(f_OUT), .SUM(Z_wire));

   always@(posedge CLK, negedge RST) begin
      if (!RST) begin
         Z_OUT <= 0;
      end
      else begin
         Z_OUT <= Z_wire[n+m+1:0];
      end
   end

endmodule   