module tb_RCA_signed();
   parameter n = 4;
   reg signed [n-1:0] A,B;
   reg C_in;
   wire C_out;
   wire signed [n-1:0] SUM;
   integer i,j,k,error;
   
   RCA_signed #(.n(n)) DUT(A,B,C_in,C_out,SUM);

   initial begin
      error = 0;
      for (i = 0; i < 4'b1111; i = i + 1) begin
         for (j = 0; j < 4'b1111; j = j + 1) begin
            for (k = 0; k < 2; k = k + 1) begin
               A = i;
               B = j;
               C_in = k;
               #1;
               if (SUM != A+B) begin
                  error = error + 1;
                  
               end
            end
            
         end
      end
   end

endmodule