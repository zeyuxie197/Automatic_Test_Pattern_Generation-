module tb_CA();
   parameter n = 4;
   reg signed [n-1:0] A,B;
   reg C_in;
   wire C_out;
   integer i,j,k,error;
   reg [n:0] golden;
   CA #(.n(n)) DUT(A,B,C_in,C_out);

   initial begin
      error = 0;
      for (i = 0; i < 4'b1111; i = i + 1) begin
         for (j = 0; j < 4'b1111; j = j + 1) begin
            for (k = 0; k < 2; k = k + 1) begin
               A = i;
               B = j;
               C_in = k;
               golden = A+B;
               #1;
               if (C_out != golden[n]) begin
                  error = error + 1;
                  
               end
            end
            
         end
      end
   end

endmodule