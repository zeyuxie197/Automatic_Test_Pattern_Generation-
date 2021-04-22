module tb_Barrett_3();
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
   wire [n+m+11:0] ZS_reg, ZC_reg;
   reg [n+m+11:0] ZS_wire, ZC_wire;
   wire [m+12:0] q_mu;
   reg [n+m+1:0] Z;

   //debug part
   

   Barrett_3 #(.n(n), .m(m)) DUT (CLK,RST,X,Y_i,M,mu,ZS_reg,ZC_reg);
   always #5 CLK = ~CLK;

   always@(*) begin
      ZS_wire = ZS_reg;
      ZC_wire = ZC_reg;
      
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

         RST = 1; //reset ZS_OUT, ZC_OUT;
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
