module buffer_router (
   clk, reset, Re, We, data_in, data_out, full, empty
);
   parameter DATA_SIZE = 64;
   input clk, reset; // syn high reset
   input Re, We;
   input [DATA_SIZE - 1:0] data_in;
   output reg [DATA_SIZE - 1:0] data_out;
   output full, empty; // indicate if buffer is full or empty;


   reg Re_do, We_do, status;
   always @(*)  begin			// check status and enable signal to determine if read or write operation can be processed
		// full = status;
		// empty = ~ status;
		if (Re && status)	Re_do = 1;
			else 			Re_do = 0;
		if (We & !status)	We_do = 1;
			else			We_do = 0;
		
	end							 

	assign full = status;
	assign empty = ~ status;

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