`include "buffer_nic.v"

module cardinal_nic (
   addr,d_in,d_out,nicEn,nicEnWr,net_si,net_ri,net_di,net_so,net_ro,net_do,net_polarity,clk,reset
);
   // Declaration of NIC
   input nicEn, nicEnWr, net_si, net_ro, net_polarity, clk, reset;
   input[0:1] addr;
   input[0:63] d_in, net_di;
   output reg[0:63] d_out, net_do;  
   output reg net_ri, net_so;
   
   // Regs needed in NIC
   wire [0:63] in_buff_out, out_buff_out; // Intermedia buffer between pe and router
   reg [0:63] in_buff_in, out_buff_in;
   wire in_status, out_status; // status of buffer - indicates empty when it is 0
   reg in_buff_re, in_buff_we; // read and write enable port for input channel
   reg out_buff_re, out_buff_we; // read and write enable port for output channel

   parameter net_in = 2'b00;
   parameter net_in_status = 2'b01;
   parameter net_out = 2'b10;
   parameter net_out_status = 2'b11;

//--------------------------------------------------------------------------------------------------
   // instantiate buffer in NIC
   buffer_nic buffer_in(.clk(clk), .reset(reset), .Re(in_buff_re), .We(in_buff_we)
                     ,.data_in(in_buff_in), .data_out(in_buff_out), .status(in_status));
   buffer_nic buffer_out(.clk(clk), .reset(reset), .Re(out_buff_re), .We(out_buff_we)
                     ,.data_in(out_buff_in), .data_out(out_buff_out), .status(out_status));
   
   // Logic between pe and NIC
   always @(*) begin
      d_out = 0;
      out_buff_we = 0;
      in_buff_re = 0;
      out_buff_in = d_in; 

      if (nicEn == 0) begin
         d_out = 0;
      end
      else begin
         if (nicEnWr == 1) begin
            if (addr == net_out) begin // when nicEn and nicEnWr are both inserted and addr specifies into net_out
               out_buff_we = 1; // attempt to write into output channel
            end
            else out_buff_we = 0; // avoid latch
         end
         else begin
            case (addr) // read operation depends on address
               net_in: begin // read input channel buffer even it is empty
                  in_buff_re = 1;
                  d_out = in_buff_out;
               end 
               net_in_status: d_out = in_status;               
               net_out_status: d_out = out_status;                                           
            endcase
         end
      end
   end

   /* Logic between router and NIC */

   always @(*) begin 
      // send data to NIC
      in_buff_in = net_di;
      net_ri = 1;
      if (in_status == 1) net_ri = 0;
      else net_ri = 1;
      if ((net_ri == 1) && (net_si == 1)) in_buff_we = 1;
      else in_buff_we = 0;

      // send data to router
      net_do = out_buff_out;
      net_so = 0;
      if ((out_status == 1) && (net_ro == 1)) begin
         net_so = net_polarity ^ out_buff_out[0];
      end
      else net_so = 0;

      if ((net_so == 1) && (net_ro == 1)) out_buff_re = 1;
      else out_buff_re = 0;
   end
endmodule