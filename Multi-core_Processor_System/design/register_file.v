/* Author: Zeyu Xie 4/1/2021
   For register_file part, there are two read ports and one write ports,
   where read is asynchronous and write is synchronous; Also, regs file has internal
   forwarding when read address and write address is the same.
*/
module register_file (
   input [0:63] wr_data_in,
   input [0:4] wr_addr_in,
   input [0:4] re_addr_in0,
   input [0:4] re_addr_in1,
   input wr_en,
   input reset,
   input clk,
   output reg [0:63] re_data_out0,
   output reg [0:63] re_data_out1
);
   reg [0:63] mem[31:1]; // declare 32x64bits mems

   // parameter b_width = 2'b00; // data width
   // parameter h_width = 2'b01;
   // parameter w_width = 2'b10;
   // parameter d_width = 2'b11;


   // read data with internal forwarding
   always @(*) begin
      if (re_addr_in0 == 0) begin
         re_data_out0 = 0;
      end
      else begin
         if ((wr_en) && (wr_addr_in == re_addr_in0) && (wr_addr_in != 0)) begin // forward r1
            re_data_out0 = wr_data_in;
         end
         else begin
            re_data_out0 = mem[re_addr_in0]; 
         end
      end

      if (re_addr_in1 == 0) begin
         re_data_out1 = 0;
      end
      else begin
         if ((wr_en) && (wr_addr_in == re_addr_in1) && (wr_addr_in != 0)) begin // forward r2
            re_data_out1 = wr_data_in;
         end
         else begin
            re_data_out1 = mem[re_addr_in1]; 
         end
      end

      
   end

   // write data into reg_file
   always @(posedge clk) begin : write
      integer i;
      if (reset) begin // reset at high sensitive
         for (i = 1; i < 32; i = i + 1) begin
            mem[i] <= 0; // reset all memory contents except mem0
         end
      end
      else begin
         if ((wr_en) && (wr_addr_in != 0)) begin
            mem[wr_addr_in] <= wr_data_in;
         end
      end
   end
endmodule