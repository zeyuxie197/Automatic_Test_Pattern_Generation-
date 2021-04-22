module buffer_nic (
   clk, reset, Re, We, data_in, data_out, status
);
   parameter DATA_SIZE = 64;
   input clk, reset; // syn high reset
   input Re, We;
   input [DATA_SIZE - 1:0] data_in;
   output reg [DATA_SIZE - 1:0] data_out;
   output reg status; // indicate if buffer is full or empty;


   wire Re_do, We_do;
   assign Re_do = (Re & status);
   assign We_do = (We & !status); // check status and enable signal to determine if read or write operation can be processed

   always @(posedge clk) begin // read or write operation in sequatial logic
      if (reset) begin
         status <= 0;
         data_out <= 0;
      end
      else begin
         if (Re_do) status <= 0;
         else if (We_do) begin
            data_out <= data_in;
            status <= 1;
         end
      end
   end
endmodule