module tb_Barrett_4();
   parameter n = 8;
   parameter m = 4;
   integer counter, ifd, ofd, check;

   reg [n-1: 0] A;
   reg [n-1: 0] B;
   // wire [n:0] Z;
   reg [2*n:0] golden;

   reg CLK,RST,CARRY_ADD,CARRY_SUB;
   reg [n-1: 0] X;
   reg [m-1: 0] Y_i;
   reg [n-1:0] M;
   reg [m+4:0] mu;
   wire [n:0] Z_OUT;

   //debug part
   wire [n+m-1:0] XY_i;
   wire [n+m-1:0] q_M;
   wire [3:0] q_i;
   wire [n:0] Z_IN;
   wire [m+7:0] q_mu;
   wire [n+m+3:0] SUB_2;

   Barrett_4 #(.n(n), .m(m)) DUT (CLK,RST,CARRY_ADD,CARRY_SUB,X,Y_i,M,mu,Z_OUT,q_i,XY_i,q_M,Z_IN,q_mu,SUB_2);
   always #5 CLK = ~CLK;

   initial begin
      CLK = 0;
      CARRY_ADD = 0;
      CARRY_SUB = 1;
      ifd = $fopen("Barrett_4_in.txt","r");
      ofd = $fopen("Barrett_4_result.txt","w");

      while (!$feof(ifd)) begin
         check = $fscanf(ifd,"%d %d %d %d %d", A, B, M, mu, golden);

         RST = 1; //reset Z_OUT;
         #1
         RST = 0;
         #9
         RST = 1;

         X = A;
         counter = n/m + 1;
         while (counter >= 1) begin
            if (counter == n/m + 1) begin
               Y_i = m*{1'b0};
               counter = counter - 1;
               #10;
            end
            else begin
               Y_i = B[(counter-1)*m +: m];
               counter = counter - 1;
               #10;
            end
         end
         
         if (Z_OUT == golden) begin
            $fdisplay (ofd, "MATCH:  A = %d, B = %d, M = %d, Z = %d, golden = %d", A, B, M, Z_OUT, golden);
         end
         else begin            
            $fdisplay (ofd, "ERROR:  A = %d, B = %d, M = %d, Z = %d, golden = %d", A, B, M, Z_OUT, golden);
            $fclose(ofd);
            $stop;
         end

      end
      $fclose(ofd);
      $stop;
   end
endmodule