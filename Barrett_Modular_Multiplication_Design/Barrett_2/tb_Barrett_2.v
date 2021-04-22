module tb_Barrett_2();
   parameter n = 24;
   parameter m = 4;
   integer counter, ifd, ofd, check;

   reg [n-1: 0] A;
   reg [n-1: 0] B;
   reg [2*n:0] golden;

   reg CLK,RST;
   reg [n-1: 0] X;
   reg [m-1: 0] Y_i;
   reg [n-1:0] M; 
   reg [m+4:0] mu;
   wire [n+m+1:0] Z_OUT;
   reg [n+m+1:0] Z_IN;
   wire [m+12:0] q_mu;
   reg [n+m+1:0] Z;

   //debug part
   wire signed [n+2*m+3:0] ADD_2,SUB_2;
   wire [n+2*m+3:0] SUB_1;
   wire [n+2*m+1:0] Z_IN_r;
   wire [n+2*m+4:0] Z_wire;
   wire [m+3:0] q_i;

   reg [5*n-1:0] q_i_g;
   reg [5*n-1:0] SUB_1_g;
   reg [5*n-1:0] ADD_2_g;

   Barrett_2 #(.n(n), .m(m)) DUT (CLK,RST,X,Y_i,M,mu,Z_OUT,ADD_2,SUB_1,SUB_2,Z_IN_r,q_mu,Z_wire,q_i);
   always #5 CLK = ~CLK;

   always@(*) begin
      Z_IN = Z_OUT;
      q_i_g = ((Z_IN/(2**(n-2))) * mu) / (2**(m+5));
      SUB_1_g = q_i_g * M * (2**m);
      ADD_2_g = Z_IN * (2**m) + X * Y_i;
      // golden = ADD_2_g - SUB_1_g;
   end


   initial begin
      CLK = 0;
      X = 0;
      Y_i = 0;
      ifd = $fopen("Barrett_2_in.txt","r");
      ofd = $fopen("Barrett_2_result.txt","w");

      while (!$feof(ifd)) begin
         $display ("begin calculating");
         check = $fscanf(ifd,"%d %d %d %d %d", A, B, M, mu, golden);

         RST = 1; //reset Z_OUT;
         #1
         RST = 0;
         #9
         RST = 1;

         X = A;
         counter = n/m;
         #5
         while (counter >= 1) begin
            Y_i = B[(counter-1)*m+ :m];
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
         // $fdisplay (ofd, "A = %d, B = %d, M = %d, Z = %d, golden = %d", A, B, M, Z, golden);
         if (Z == golden) begin
            $fdisplay (ofd, "MATCH:  A = %d, B = %d, M = %d, mu = %d, Z = %d, golden = %d", A, B, M, mu, Z, golden);
         end
         else begin            
            $fdisplay (ofd, "ERROR:  A = %d, B = %d, M = %d, mu = %d,  Z = %d, golden = %d", A, B, M, mu, Z, golden);
            $fclose(ofd);
            $stop;
         end

      end
      $fclose(ofd);
      $stop;
   end
endmodule