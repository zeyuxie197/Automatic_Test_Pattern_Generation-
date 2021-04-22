`include "CSA.v"
`include "RCA.v"
`include "Booth_coding.v"
module Barrett_3(CLK,RST,X,Y_i,M,mu,ZS_reg,ZC_reg);
   parameter n = 1024;
   parameter m = 4;

   input CLK,RST;
   input [n-1:0] X;
   input [m-1:0] Y_i;
   input [n-1:0] M;
   input [m+6:0] mu;
   output reg [n+m+11:0] ZS_reg, ZC_reg;

   //(ZS + ZC)r
   wire [n+m+11:0] ZS_wire, ZC_wire;
   wire [n+2*m+11:0] ZS_r, ZC_r;
   
   assign ZS_wire = ZS_reg;
   assign ZC_wire = ZC_reg;
   assign ZS_r = {ZS_wire, {m{1'b0}}};
   assign ZC_r = {ZC_wire, {m{1'b0}}};

   //XY_i
   wire [n+2*m+11:0] xP0,xP1,xP2,xP3,xS1,xC1,xS2,xC2;

   assign xP0 = {{(2*m+12){1'b0}},{X & {n{Y_i[0]}}}};
   assign xP1 = {{(2*m+11){1'b0}},{X & {n{Y_i[1]}}},{1'b0}};
   assign xP2 = {{(2*m+10){1'b0}},{X & {n{Y_i[2]}}},{2{1'b0}}};
   assign xP3 = {{(2*m+9){1'b0}},{X & {n{Y_i[3]}}},{3{1'b0}}};

   CSA #(.n(n+2*m+12)) xcsa1(.X(xP0),.Y(xP1),.Z(xP2),.S(xS1),.C(xC1));
   CSA #(.n(n+2*m+12)) xcsa2(.X(xP3),.Y(xS1),.Z(xC1),.S(xS2),.C(xC2)); //X * Y_i compress to 2 (n+2*m+12);

   //q_i
   wire [m+3:0] ZSH, ZCH; // m + 4 bits;
   wire [m+6:0] ZSH_extend, ZCH_extend, QSH, QCH; // m + 7 bits;
   wire [m+8:0] QSH_extend, QCH_extend; // m + 9 bits;
   wire Z_carry, Q_carry;
   wire [4:0] QS_SIGN, QC_SIGN, QMS_SIGN, QMC_SIGN;
   wire [2*m+11:0] QSP0, QSP1, QSP2, QSP3, QSP4, QCP0, QCP1, QCP2, QCP3, QCP4, QZP;
   wire [2*m+11:0] QS1,QC1,QS2,QC2,QS3,QC3,QS4,QC4,QS5,QC5,QS6,QC6,QS7,QC7,QS8,QC8,QS9,QC9;
   wire [n+m+9:0] QMSP0, QMSP1, QMSP2, QMSP3, QMSP4, QMSP5, QMCP0, QMCP1, QMCP2, QMCP3, QMCP4, QMCP5, QMP;
   wire [n+m+9:0] QMS1,QMC1,QMS2,QMC2,QMS3,QMC3,QMS4,QMC4,QMS5,QMC5,QMS6,QMC6,QMS7,QMC7,QMS8,QMC8,QMS9,QMC9,QMS10,QMC10,QMS11,QMC11;
   wire [n+2*m+11:0] QMRS,QMRC;
   wire signed [n+2*m+11:0] QMRS_NEG,QMRC_NEG;

   assign ZSH = ZS_wire[n+m+1:n-2];
   assign ZCH = ZC_wire[n+m+1:n-2];
   assign ZSH_extend = {2'b00, ZSH, 1'b0};
   assign ZCH_extend = {2'b00, ZCH, 1'b0};
   RCA #(.n(2)) zrca(.A(ZS_wire[n-3:n-4]),.B(ZC_wire[n-3:n-4]),.C_in({1'b0}),.C_out(Z_carry));

   // for m = 4:
   Booth_Encoder qbs0 (ZSH_extend[0],ZSH_extend[1],ZSH_extend[2], mu, QS_SIGN[0], QSP0[m+7:0]);
   Booth_Encoder qbs1 (ZSH_extend[2],ZSH_extend[3],ZSH_extend[4], mu, QS_SIGN[1], QSP1[m+9:2]);
   Booth_Encoder qbs2 (ZSH_extend[4],ZSH_extend[5],ZSH_extend[6], mu, QS_SIGN[2], QSP2[m+11:4]);
   Booth_Encoder qbs3 (ZSH_extend[6],ZSH_extend[7],ZSH_extend[8], mu, QS_SIGN[3], QSP3[m+13:6]);
   Booth_Encoder qbs4 (ZSH_extend[8],ZSH_extend[9],ZSH_extend[10], mu, QS_SIGN[4], QSP4[m+15:8]);

   assign QSP0[2*m+11:m+8] = {{(m+1){1'b0}},~QS_SIGN[0],QS_SIGN[0],QS_SIGN[0]};
   assign QSP1[1:0] = {1'b0, QS_SIGN[0]};
   assign QSP1[2*m+11:m+10] = {{(m){1'b0}},1'b1,~QS_SIGN[1]};
   assign QSP2[3:0] = {1'b0, QS_SIGN[1], {2{1'b0}}};
   assign QSP2[2*m+11:m+12] = {{(m-2){1'b0}},1'b1,~QS_SIGN[2]};
   assign QSP3[5:0] = {1'b0, QS_SIGN[2], {4{1'b0}}};
   assign QSP3[2*m+11:m+12] = {1'b1,~QS_SIGN[3]};
   assign QSP4[7:0] = {1'b0, QS_SIGN[3], {6{1'b0}}};

   Booth_Encoder qbc0 (ZCH_extend[0],ZCH_extend[1],ZCH_extend[2], mu, QC_SIGN[0], QCP0[m+7:0]);
   Booth_Encoder qbc1 (ZCH_extend[2],ZCH_extend[3],ZCH_extend[4], mu, QC_SIGN[1], QCP1[m+9:2]);
   Booth_Encoder qbc2 (ZCH_extend[4],ZCH_extend[5],ZCH_extend[6], mu, QC_SIGN[2], QCP2[m+11:4]);
   Booth_Encoder qbc3 (ZCH_extend[6],ZCH_extend[7],ZCH_extend[8], mu, QC_SIGN[3], QCP3[m+13:6]);
   Booth_Encoder qbc4 (ZCH_extend[8],ZCH_extend[9],ZCH_extend[10], mu, QC_SIGN[4], QCP4[m+15:8]);
   
   assign QCP0[2*m+11:m+8] = {{(m+1){1'b0}},~QC_SIGN[0],QC_SIGN[0],QC_SIGN[0]};
   assign QCP1[1:0] = {1'b0, QC_SIGN[0]};
   assign QCP1[2*m+11:m+10] = {{(m){1'b0}},1'b1,~QC_SIGN[1]};
   assign QCP2[3:0] = {1'b0, QC_SIGN[1], {2{1'b0}}};
   assign QCP2[2*m+11:m+12] = {{(m-2){1'b0}},1'b1,~QC_SIGN[2]};
   assign QCP3[5:0] = {1'b0, QC_SIGN[2], {4{1'b0}}};
   assign QCP3[2*m+11:m+12] = {1'b1,~QC_SIGN[3]};
   assign QCP4[7:0] = {1'b0, QC_SIGN[3], {6{1'b0}}};

   assign QZP = {{9{1'b0}},{mu & {(m+7){Z_carry}}};

   CSA #(.n(2*m+12)) qcsa1(.X(QSP0),.Y(QSP1),.Z(QSP2),.S(QS1),.C(QC1));
   CSA #(.n(2*m+12)) qcsa2(.X(QSP3),.Y(QSP4),.Z(QCP0),.S(QS2),.C(QC2));
   CSA #(.n(2*m+12)) qcsa3(.X(QCP1),.Y(QCP2),.Z(QCP3),.S(QS3),.C(QC3));

   CSA #(.n(2*m+12)) qcsa4(.X(QCP4),.Y(QZP),.Z(QS1),.S(QS4),.C(QC4));
   CSA #(.n(2*m+12)) qcsa5(.X(QC1),.Y(QS2),.Z(QC2),.S(QS5),.C(QC5));

   CSA #(.n(2*m+12)) qcsa6(.X(QS3),.Y(QC3),.Z(QS4),.S(QS6),.C(QC6));
   CSA #(.n(2*m+12)) qcsa7(.X(QC4),.Y(QS5),.Z(QC5),.S(QS7),.C(QC7));

   CSA #(.n(2*m+12)) qcsa8(.X(QS6),.Y(QC6),.Z(QS7),.S(QS8),.C(QC8));

   CSA #(.n(2*m+12)) qcsa9(.X(QC7),.Y(QS8),.Z(QC8),.S(QS9),.C(QC9));
   
   //q_iMr
   assign QSH = QS9[2*m+11:m+5]; // m + 7 bits;
   assign QCH = QC9[2*m+11:m+5];
   assign QSH_extend = {1'b0, QSH, 1'b0};
   assign QCH_extend = {1'b0, QCH, 1'b0}; // m + 9 bits;
   RCA #(.n(m+5)) qrca(.A(QS9[m+4:0]),.B(QC9[m+4:0]),.C_in({1'b0}),.C_out(Q_carry));

   Booth_Encoder qmbs0 (QSH_extend[0],QSH_extend[1],QSH_extend[2], M, QMS_SIGN[0], QMSP0[n:0]);
   Booth_Encoder qmbs1 (QSH_extend[2],QSH_extend[3],QSH_extend[4], M, QMS_SIGN[1], QMSP1[n+2:2]);
   Booth_Encoder qmbs2 (QSH_extend[4],QSH_extend[5],QSH_extend[6], M, QMS_SIGN[2], QMSP2[n+4:4]);
   Booth_Encoder qmbs3 (QSH_extend[6],QSH_extend[7],QSH_extend[8], M, QMS_SIGN[3], QMSP3[n+6:6]);
   Booth_Encoder qmbs4 (QSH_extend[8],QSH_extend[9],QSH_extend[10], M, QMS_SIGN[4], QMSP4[n+8:8]);
   Booth_Encoder qmbs5 (QSH_extend[10],QSH_extend[11],QSH_extend[12], M, QMS_SIGN[5], QMSP5[n+10:10]);

   assign QMSP0[n+m+9:n+1] = {{(m+6){1'b0}},~QMS_SIGN[0],QMS_SIGN[0],QMS_SIGN[0]};
   assign QMSP1[1:0] = {1'b0, QMS_SIGN[0]};
   assign QMSP1[n+m+9:n+3] = {{(m+5){1'b0}},1'b1,~QMS_SIGN[1]};
   assign QMSP2[3:0] = {1'b0, QMS_SIGN[1], {2{1'b0}}};
   assign QMSP2[n+m+9:n+5] = {{(m+3){1'b0}},1'b1,~QMS_SIGN[2]};
   assign QMSP3[5:0] = {1'b0, QMS_SIGN[2], {4{1'b0}}};
   assign QMSP3[n+m+9:n+7] = {(m+1){1'b0}},1'b1,~QMS_SIGN[3]};
   assign QMSP4[7:0] = {1'b0, QMS_SIGN[3], {6{1'b0}}};
   assign QMSP4[n+m+9:n+9] = {(m-1){1'b0}},1'b1,~QMS_SIGN[4]};
   assign QMSP5[9:0] = {1'b0, QMS_SIGN[4], {8{1'b0}}};
   assign QMSP5[n+m+9:n+11] = {(m-1){1'b0}};


   Booth_Encoder qmbc0 (QCH_extend[0],QCH_extend[1],QCH_extend[2], M, QMC_SIGN[0], QMCP0[n:0]);
   Booth_Encoder qmbc1 (QCH_extend[2],QCH_extend[3],QCH_extend[4], M, QMC_SIGN[1], QMCP1[n+2:2]);
   Booth_Encoder qmbc2 (QCH_extend[4],QCH_extend[5],QCH_extend[6], M, QMC_SIGN[2], QMCP2[n+4:4]);
   Booth_Encoder qmbc3 (QCH_extend[6],QCH_extend[7],QCH_extend[8], M, QMC_SIGN[3], QMCP3[n+6:6]);
   Booth_Encoder qmbc4 (QCH_extend[8],QCH_extend[9],QCH_extend[10], M, QMC_SIGN[4], QMCP4[n+8:8]);
   Booth_Encoder qmbc5 (QCH_extend[10],QCH_extend[11],QCH_extend[12], M, QMC_SIGN[5], QMCP5[n+10:10]);

   assign QMCP0[n+m+9:n+1] = {{(m+6){1'b0}},~QMC_SIGN[0],QMC_SIGN[0],QMC_SIGN[0]};
   assign QMCP1[1:0] = {1'b0, QMC_SIGN[0]};
   assign QMCP1[n+m+9:n+3] = {{(m+5){1'b0}},1'b1,~QMC_SIGN[1]};
   assign QMCP2[3:0] = {1'b0, QMC_SIGN[1], {2{1'b0}}};
   assign QMCP2[n+m+9:n+5] = {{(m+3){1'b0}},1'b1,~QMC_SIGN[2]};
   assign QMCP3[5:0] = {1'b0, QMC_SIGN[2], {4{1'b0}}};
   assign QMCP3[n+m+9:n+7] = {(m+1){1'b0}},1'b1,~QMC_SIGN[3]};
   assign QMCP4[7:0] = {1'b0, QMC_SIGN[3], {6{1'b0}}};
   assign QMCP4[n+m+9:n+9] = {(m-1){1'b0}},1'b1,~QMC_SIGN[4]};
   assign QMCP5[9:0] = {1'b0, QMC_SIGN[4], {8{1'b0}}};
   assign QMCP5[n+m+9:n+11] = {(m-1){1'b0}};

   assign QMP = {{(m+10){1'b0}},{M & {(n){Q_carry}}};

   CSA #(.n(n+m+10)) qmcsa1(.X(QMSP0),.Y(QMSP1),.Z(QMSP2),.S(QMS1),.C(QMC1));
   CSA #(.n(n+m+10)) qmcsa2(.X(QMSP3),.Y(QMSP4),.Z(QMSP5),.S(QMS2),.C(QMC2));
   CSA #(.n(n+m+10)) qmcsa3(.X(QMCP0),.Y(QMCP1),.Z(QMCP2),.S(QMS3),.C(QMC3));
   CSA #(.n(n+m+10)) qmcsa4(.X(QMCP3),.Y(QMCP4),.Z(QMCP5),.S(QMS4),.C(QMC4));
   
   CSA #(.n(n+m+10)) qmcsa5(.X(QMP),.Y(QMS1),.Z(QMC1),.S(QMS5),.C(QMC5));
   CSA #(.n(n+m+10)) qmcsa6(.X(QMS2),.Y(QMC2),.Z(QMS3),.S(QMS6),.C(QMC6));
   CSA #(.n(n+m+10)) qmcsa7(.X(QMC3),.Y(QMS4),.Z(QMC4),.S(QMS7),.C(QMC7));

   CSA #(.n(n+m+10)) qmcsa8(.X(QMS5),.Y(QMC5),.Z(QMS6),.S(QMS8),.C(QMC8));
   CSA #(.n(n+m+10)) qmcsa9(.X(QMC6),.Y(QMS7),.Z(QMC7),.S(QMS9),.C(QMC9));

   CSA #(.n(n+m+10)) qmcsa10(.X(QMS8),.Y(QMC8),.Z(QMS9),.S(QMS10),.C(QMC10));

   CSA #(.n(n+m+10)) qmcsa11(.X(QMC9),.Y(QMS10),.Z(QMC10),.S(QMS11),.C(QMC11)); // q_iM;

   assign QMRS = {{2'b00}, QMS11, {m{1'b0}}};
   assign QMRC = {{2'b00}, QMC11, {m{1'b0}}}; //q_iMr;

   RCA #(.n(n+2*m+12)) qmrca1(.A(~QMRS),.B(0),.C_in({1'b1}),.SUM(QMRS_NEG);
   RCA #(.n(n+2*m+12)) qmrca2(.A(~QMRC),.B(0),.C_in({1'b1}),.SUM(QMRC_NEG);

   //Final Compress
   wire [n+2*m+11:0] FS1,FC1,FS2,FC2,FS3,FC3,FS4,FC4;
   wire [n+2*m+11:0] ZS_p, ZC_p;

   CSA #(.n(n+2*m+12)) qmcsa10(.X(ZS_r),.Y(ZC_r),.Z(xS2),.S(FS1),.C(FC1));
   CSA #(.n(n+2*m+12)) qmcsa10(.X(xC2),.Y(QMRS_NEG),.Z(QMRC_NEG),.S(FS2),.C(FC2));

   CSA #(.n(n+2*m+12)) qmcsa10(.X(FS1),.Y(FC1),.Z(FS2),.S(FS3),.C(FC3));

   CSA #(.n(n+2*m+12)) qmcsa10(.X(FC2),.Y(FS3),.Z(FC3),.S(FS4),.C(FC4));

   assign ZS_p = {{FS4[n+2*m+11] ^ FC4[n+2*m+11]}, FS4[n+2*m+10:0]};
   assign ZC_p = {{1'b0}, FC4[n+2*m+10:0]};

   always@(posedge CLK, negedge RST) begin
      if (!RST) begin
         ZS_reg <= 0;
         ZC_reg <= 0;
      end
      else begin
         ZS_reg <= ZS_p[n+m+11:0];
         ZC_reg <= ZC_p[n+m+11:0];
      end
   end

endmodule
