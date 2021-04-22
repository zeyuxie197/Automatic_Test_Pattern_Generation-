module tb_Booth_Encoder ();
   parameter n = 8;

   reg X_low, X, X_high;
   reg [n-1:0] Y;
   wire SIGN;
   wire [n:0] PP;

   Booth_Encoder #(.n(n))  DUT (X_low, X, X_high, Y, SIGN, PP);
   initial begin
      Y = 8'hA9;
      X_low = 0;
      X = 1;
      X_high = 1;
      #5
      Y = 8'hA9;
      X_low = 1;
      X = 1;
      X_high = 0;
      #5
      Y = 8'hA9;
      X_low = 0;
      X = 1;
      X_high = 0;
      #5
      Y = 8'hA9;
      X_low = 0;
      X = 0;
      X_high = 1;
      #5
      $stop;
   end
endmodule