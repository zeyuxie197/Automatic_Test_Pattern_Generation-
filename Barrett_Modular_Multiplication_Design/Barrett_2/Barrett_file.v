module Barrett_2_reg (CLK,RST,X,Y_i,M,mu,Z_OUT,q_i);
   parameter n = 8;
   parameter m = 4;

   input CLK, RST;
   input [n-1:0] X;
   input [m-1:0] Y_i;
   input [n-1:0] M;
   input [m+6:0] mu;
   output [2*n-1:0] Z_OUT;
   output [2:0] q_i;

   wire [2:0] q_i;
   wire [2*n-1:0] Z_IN;
   wire [2*n-1:0] Z_OUT_wire;
   reg [2*n-1:0] Z_OUT;

   assign Z_IN = Z_OUT;
   assign q_i = ((Z_IN/(2**(n-2))) * mu) / (2**(m+5));
   assign Z_OUT_wire = Z_IN * (2**m) + X*Y_i - q_i*M*(2**m);
   
   always@(posedge CLK, negedge RST) begin
      if (!RST) begin
         Z_OUT <= 0;
      end
      else begin
         Z_OUT <= Z_OUT_wire;
      end
   end
endmodule