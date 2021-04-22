module tb_Multiplier_4xN();
   parameter n = 16;
   reg [3:0] A;
   reg [n-1:0] B;
   wire [n+3:0] M_OUT;
   
   integer error,i,j;
   Multiplier_4xN #(.n(n)) DUT(A,B,M_OUT);

   initial begin
      error = 0;
      for (i = 0; i <= 4'b1111; i = i + 1) begin
         assign A = i;
         for (j = 0; j <= {n{1'b1}}; j = j + 1) begin
            assign B = j;
            #1;
            if (M_OUT != A*B) begin
               error = error + 1;
            end
         end
      end
      
   end
endmodule   