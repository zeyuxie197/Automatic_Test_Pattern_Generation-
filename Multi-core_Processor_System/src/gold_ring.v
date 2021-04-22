`include "gold_router.v"

module gold_ring (
   input clk, reset, 
   // ports on router 0
   input node0_pesi,
   input [63:0] node0_pedi,
   output node0_peri,
   output node0_peso,
   input node0_pero,
   output [63:0] node0_pedo,
   output node0_polarity,
   // ports on router 1
   input node1_pesi,
   input [63:0] node1_pedi,
   output node1_peri,
   output node1_peso,
   input node1_pero,
   output [63:0] node1_pedo,
   output node1_polarity,
   // ports on router 2
   input node2_pesi,
   input [63:0] node2_pedi,
   output node2_peri,
   output node2_peso,
   input node2_pero,
   output [63:0] node2_pedo,
   output node2_polarity,
   // ports on router 3
   input node3_pesi,
   input [63:0] node3_pedi,
   output node3_peri,
   output node3_peso,
   input node3_pero,
   output [63:0] node3_pedo,
   output node3_polarity
);
   // intermediate wire between two routers
   wire cws_0, cws_1, cws_2, cws_3;
   wire cwr_0, cwr_1, cwr_2, cwr_3;
   wire [63:0] cwd_0, cwd_1, cwd_2, cwd_3;
   wire ccws_0, ccws_1, ccws_2, ccws_3;
   wire ccwr_0, ccwr_1, ccwr_2, ccwr_3;
   wire [63:0] ccwd_0, ccwd_1, ccwd_2, ccwd_3;

   // instantiate routers
   gold_router router0(
      .clk(clk), .reset(reset), .polarity(node0_polarity),
      .cwsi(cws_3), .cwri(cwr_3), .cwdi(cwd_3),
      .ccwsi(ccws_1), .ccwri(ccwr_1), .ccwdi(ccwd_1),
      .pesi(node0_pesi), .peri(node0_peri), .pedi(node0_pedi),
      .cwso(cws_0), .cwro(cwr_0), .cwdo(cwd_0),
      .ccwso(ccws_0), .ccwro(ccwr_0), .ccwdo(ccwd_0),
      .peso(node0_peso), .pero(node0_pero), .pedo(node0_pedo)
   );
   gold_router router1(
      .clk(clk), .reset(reset), .polarity(node1_polarity), 
      .cwsi(cws_0), .cwri(cwr_0), .cwdi(cwd_0),
      .ccwsi(ccws_2), .ccwri(ccwr_2), .ccwdi(ccwd_2),
      .pesi(node1_pesi), .peri(node1_peri), .pedi(node1_pedi),
      .cwso(cws_1), .cwro(cwr_1), .cwdo(cwd_1),
      .ccwso(ccws_1), .ccwro(ccwr_1), .ccwdo(ccwd_1),
      .peso(node1_peso), .pero(node1_pero), .pedo(node1_pedo)
   );
   gold_router router2(
      .clk(clk), .reset(reset), .polarity(node2_polarity),
      .cwsi(cws_1), .cwri(cwr_1), .cwdi(cwd_1),
      .ccwsi(ccws_3), .ccwri(ccwr_3), .ccwdi(ccwd_3),
      .pesi(node2_pesi), .peri(node2_peri), .pedi(node2_pedi),
      .cwso(cws_2), .cwro(cwr_2), .cwdo(cwd_2),
      .ccwso(ccws_2), .ccwro(ccwr_2), .ccwdo(ccwd_2),
      .peso(node2_peso), .pero(node2_pero), .pedo(node2_pedo)
   );
   gold_router router3(
      .clk(clk), .reset(reset), .polarity(node3_polarity),
      .cwsi(cws_2), .cwri(cwr_2), .cwdi(cwd_2),
      .ccwsi(ccws_0), .ccwri(ccwr_0), .ccwdi(ccwd_0),
      .pesi(node3_pesi), .peri(node3_peri), .pedi(node3_pedi),
      .cwso(cws_3), .cwro(cwr_3), .cwdo(cwd_3),
      .ccwso(ccws_3), .ccwro(ccwr_3), .ccwdo(ccwd_3),
      .peso(node3_peso), .pero(node3_pero), .pedo(node3_pedo)
   );

   // generate polarity
   reg polarity;
   always @(posedge clk) begin
      if (reset) polarity <= 0;
      else polarity <= ~polarity;
   end

   // combinational block for NIC polarity
   assign node0_polarity = polarity;
   assign node1_polarity = polarity;
   assign node2_polarity = polarity;
   assign node3_polarity = polarity;
endmodule