module tb_Barrett_2_reg();
   parameter n = 8;
   parameter m = 4;
   integer counter, ifd, ofd, check;

   reg [n-1:0] A,B;

   reg CLK, RST;
   reg [n-1:0] X;
   reg [m-1:0] Y_i;
   reg [n-1:0] M;
   reg [m+6:0] mu;
   reg [2*n-1:0] golden;
   wire [2*n-1:0] Z_OUT;
   reg [2*n-1:0] Z;
   wire [2:0] q_i;
   

   Barrett_2_reg #(.n(n),.m(m)) DUT (CLK,RST,X,Y_i,M,mu,Z_OUT,q_i);

   initial begin
      CLK = 0;
      X = 0;
      Y_i = 0;
      ifd = $fopen("Barrett_2_test.txt","r");
      ofd = $fopen("Barrett_2_golden.txt","w");

      while (!$feof(ifd)) begin
         check = $fscanf(ifd,"%d %d %d", A, B, M);
         assign mu = 2**(n+m+3) / M;
         RST = 1; //reset Z_OUT;
         #1
         RST = 0;
         #9
         RST = 1;

         X = A;
         counter = n/m;
         while (counter >= 1) begin
               Y_i = B[counter*m +: m];
               counter = counter - 1;
               #10;
         end
         // last iteration:
         Y_i = {m{1'b0}};
         #10
         Z = Z_OUT >> m;
         #10
         if (Z > M) begin
            Z = Z - M;
         end
         else begin
            Z = Z;
         end
         $fdisplay (ofd, "A = %d B = %d M = %d mu = %d Z = %d", A, B, M, mu, Z);
      end
      $fclose(ofd);
      $stop;
   end

   
endmodule