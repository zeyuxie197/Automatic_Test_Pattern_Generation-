`timescale 1ns/1ps
module tb_NIC (
   
);
   parameter CLK_CYCLE = 4;
   parameter PAC_NUM = 10000; // if pe and router can receive all data from 0 to 10000 which means function correctly

   // ports in NIC
   reg nicEn, nicEnWr, net_si, net_ro, net_polarity, clk, reset;
   reg [0:1] addr;
   reg [0:63] d_in, net_di;
   wire [0:63] d_out, net_do;
   wire net_ri, net_so;

   // instantiation of DUT
   cardinal_nic NIC_DUT (
      addr,d_in,d_out,nicEn,nicEnWr,net_si,net_ri,net_di,
      net_so,net_ro,net_do,net_polarity,clk,reset);
   
   // generate 250 MHZ clock signal and polarity signal
   always #(0.5 * CLK_CYCLE) clk <= ~clk;
   
   always @(posedge clk) begin
      if (reset) net_polarity <= 0;
      else net_polarity <= ~net_polarity;
   end

   // report data that received from NIC
   integer data_pe, data_router;

   initial begin
      data_pe = $fopen("data_pe.out", "w");
      data_router = $fopen("data_router.out", "w");
   end

   reg pe_flag;
   integer i;
   initial begin : test
      
      clk = 1;
      reset = 1;
      nicEn = 1;
      nicEnWr = 0;
      net_ro = 0;
      net_si = 0;
      pe_flag = 0;

      #(7.5 * CLK_CYCLE)
      reset = 0; // reset for 7 cycles

      // send data from router
      for (i = 0; i < PAC_NUM; i = i + 1) begin
         wait(net_ri) begin
            #(0.1 * CLK_CYCLE)
            net_si = 1;
            net_di = i;
            #(CLK_CYCLE)
            net_si = 0; // after one clock, set net_si back to 0
         end
      end
      #(5 * CLK_CYCLE)
      pe_flag = 1; // now starting send data from pe
      #(5 * CLK_CYCLE);
   
      // send data from pe
      i = 0;
      while (i < PAC_NUM) begin
         #(0.1 * CLK_CYCLE)
         addr = 2'b11;
         #(0.1 * CLK_CYCLE)
         
         if (d_out[63] == 0) begin // indicate output buff is empty
            addr = 2'b10;
            nicEnWr = 1;
            d_in = i;
            d_in[0] = i % 2; // change vc bit to verify polarity correctness
            i = i + 1;
         end
         #(0.8 * CLK_CYCLE)
         nicEnWr = 0;
      end

      #(5 * CLK_CYCLE)
      $fclose(data_pe);     
      $fclose(data_router);
      $finish;     
   end

   // receive data in router
   initial begin
      #(7.5 * CLK_CYCLE)
      forever @(posedge clk) begin
         net_ro = 1;
         #(0.1 * CLK_CYCLE)
         if (net_so) begin
            $fdisplay(data_router, "%d", net_do[32:63]); // report data in router
         end
      end   
   end

   // receive data in pe
   initial begin : pe_part
      #(7.5 * CLK_CYCLE)
      forever begin
         if (pe_flag == 1) begin 
            disable pe_part; // disable this part if sending from router finished
         end
         
         addr = 2'b01;
         #(0.1 * CLK_CYCLE)
         if (d_out[63]) begin // indicate input buffer is full
            addr = 2'b00;
            #(0.1 * CLK_CYCLE)
            $fdisplay(data_pe, "%d", d_out[32:63]);
         end
         else #(0.1 * CLK_CYCLE);
         #(0.8 * CLK_CYCLE);
      end
   end
endmodule