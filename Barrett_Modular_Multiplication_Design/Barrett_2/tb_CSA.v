module tb_CSA();
   parameter n = 6;

   reg [n-1:0] X,Y,Z;
   wire [n-1:0] S;
   wire [n-1:0] C;

   CSA #(.n(n)) csa(X,Y,Z,S,C);
   initial begin
      X = 6'b001001;
      Y = 6'b001111;
      Z = 6'b001101;
      #5
      $stop;
   end
endmodule