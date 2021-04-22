`include "cardinal_cpu.v"
`include "cardinal_nic.v"
`include "gold_ring.v"

module cardinal_cmp (
   input clk, reset, 
   // ports on node 0
	input [0:31] node0_inst_in,		//Instruction from the Instruction Memory
	input [0:63] node0_d_in,		// Data from Data Memory
	output [0:31] node0_pc_out,		// Program Counter
	output [0:63] node0_d_out,		// Write Data to Data Memory
	output [0:31] node0_addr_out,         // Write Address for Data Memory
	output  node0_memWrEn,          // Data Memory Write Enable
	output  node0_memEn,            // Data Memory Enable

   // ports on node 1
	input [0:31] node1_inst_in,		//Instruction from the Instruction Memory
	input [0:63] node1_d_in,		// Data from Data Memory
	output [0:31] node1_pc_out,		// Program Counter
	output [0:63] node1_d_out,		// Write Data to Data Memory
	output [0:31] node1_addr_out,         // Write Address for Data Memory
	output  node1_memWrEn,          // Data Memory Write Enable
	output  node1_memEn,            // Data Memory Enable

   // ports on node 2
	input [0:31] node2_inst_in,		//Instruction from the Instruction Memory
	input [0:63] node2_d_in,		// Data from Data Memory
	output [0:31] node2_pc_out,		// Program Counter
	output [0:63] node2_d_out,		// Write Data to Data Memory
	output [0:31] node2_addr_out,         // Write Address for Data Memory
	output  node2_memWrEn,          // Data Memory Write Enable
	output  node2_memEn,            // Data Memory Enable

   // ports on node 3
	input [0:31] node3_inst_in,		//Instruction from the Instruction Memory
	input [0:63] node3_d_in,		// Data from Data Memory
	output [0:31] node3_pc_out,		// Program Counter
	output [0:63] node3_d_out,		// Write Data to Data Memory
	output [0:31] node3_addr_out,         // Write Address for Data Memory
	output  node3_memWrEn,          // Data Memory Write Enable
	output  node3_memEn           // Data Memory Enable
);

   // Intermidate wire between cpu and NIC
   wire [0:1] node0_addr_nic, node1_addr_nic, node2_addr_nic, node3_addr_nic;
   wire [0:63] node0_din_nic, node1_din_nic, node2_din_nic, node3_din_nic;
   wire [0:63] node0_dout_nic, node1_dout_nic, node2_dout_nic, node3_dout_nic;
   wire node0_nicEn, node1_nicEn, node2_nicEn, node3_nicEn;
   wire node0_nicWrEn, node1_nicWrEn, node2_nicWrEn, node3_nicWrEn;


   wire node0_net_so, node1_net_so, node2_net_so, node3_net_so;
   wire node0_net_ro, node1_net_ro, node2_net_ro, node3_net_ro;
   wire node0_net_polarity, node1_net_polarity, node2_net_polarity, node3_net_polarity;
   wire node0_net_si, node1_net_si, node2_net_si, node3_net_si;
   wire node0_net_ri, node1_net_ri, node2_net_ri, node3_net_ri;
   wire [0:63] node0_net_do, node1_net_do, node2_net_do, node3_net_do;
   wire [0:63] node0_net_di, node1_net_di, node2_net_di, node3_net_di;
   // Instantiate cpu
   // first cpu
   cardinal_cpu cpu0 (.clk(clk),               
					 .reset(reset),           
					 .inst_in(node0_inst_in),  
					 .d_in(node0_d_in),           
					 .pc_out(node0_pc_out), 
					 .d_out(node0_d_out),         
					 .addr_out(node0_addr_out),     
					 .memWrEn(node0_memWrEn),       
					 .memEn(node0_memEn),           
					 .addr_nic(node0_addr_nic),    
					 .din_nic(node0_din_nic),       
					 .dout_nic(node0_dout_nic),     
					 .nicEn(node0_nicEn),          
					 .nicWrEn(node0_nicWrEn));

   // second cpu
   cardinal_cpu cpu1 (.clk(clk),               
					 .reset(reset),           
					 .inst_in(node1_inst_in),  
					 .d_in(node1_d_in),           
					 .pc_out(node1_pc_out), 
					 .d_out(node1_d_out),         
					 .addr_out(node1_addr_out),     
					 .memWrEn(node1_memWrEn),       
					 .memEn(node1_memEn),           
					 .addr_nic(node1_addr_nic),    
					 .din_nic(node1_din_nic),       
					 .dout_nic(node1_dout_nic),     
					 .nicEn(node1_nicEn),          
					 .nicWrEn(node1_nicWrEn));

   // third cpu
   cardinal_cpu cpu2 (.clk(clk),               
					 .reset(reset),           
					 .inst_in(node2_inst_in),  
					 .d_in(node2_d_in),           
					 .pc_out(node2_pc_out), 
					 .d_out(node2_d_out),         
					 .addr_out(node2_addr_out),     
					 .memWrEn(node2_memWrEn),       
					 .memEn(node2_memEn),           
					 .addr_nic(node2_addr_nic),    
					 .din_nic(node2_din_nic),       
					 .dout_nic(node2_dout_nic),     
					 .nicEn(node2_nicEn),          
					 .nicWrEn(node2_nicWrEn));

   // fourth cpu
   cardinal_cpu cpu3 (.clk(clk),               
					 .reset(reset),           
					 .inst_in(node3_inst_in),  
					 .d_in(node3_d_in),           
					 .pc_out(node3_pc_out), 
					 .d_out(node3_d_out),         
					 .addr_out(node3_addr_out),     
					 .memWrEn(node3_memWrEn),       
					 .memEn(node3_memEn),           
					 .addr_nic(node3_addr_nic),    
					 .din_nic(node3_din_nic),       
					 .dout_nic(node3_dout_nic),     
					 .nicEn(node3_nicEn),          
					 .nicWrEn(node3_nicWrEn));

   // Instantiate NIC
  
   // first NIC
   cardinal_nic nic0 (.clk(clk),
             .reset(reset),
             .nicEn(node0_nicEn),
             .nicEnWr(node0_nicWrEn),
             .d_in(node0_din_nic),
             .d_out(node0_dout_nic),
             .addr(node0_addr_nic),
             .net_so(node0_net_so),
             .net_ro(node0_net_ro),
             .net_do(node0_net_do),
             .net_polarity(node0_net_polarity),
             .net_si(node0_net_si),
             .net_ri(node0_net_ri),
             .net_di(node0_net_di));

   // second NIC
   cardinal_nic nic1 (.clk(clk),
             .reset(reset),
             .nicEn(node1_nicEn),
             .nicEnWr(node1_nicWrEn),
             .d_in(node1_din_nic),
             .d_out(node1_dout_nic),
             .addr(node1_addr_nic),
             .net_so(node1_net_so),
             .net_ro(node1_net_ro),
             .net_do(node1_net_do),
             .net_polarity(node1_net_polarity),
             .net_si(node1_net_si),
             .net_ri(node1_net_ri),
             .net_di(node1_net_di));

   // third NIC
   cardinal_nic nic2 (.clk(clk),
             .reset(reset),
             .nicEn(node2_nicEn),
             .nicEnWr(node2_nicWrEn),
             .d_in(node2_din_nic),
             .d_out(node2_dout_nic),
             .addr(node2_addr_nic),
             .net_so(node2_net_so),
             .net_ro(node2_net_ro),
             .net_do(node2_net_do),
             .net_polarity(node2_net_polarity),
             .net_si(node2_net_si),
             .net_ri(node2_net_ri),
             .net_di(node2_net_di));

   // fourth NIC
   cardinal_nic nic3 (.clk(clk),
             .reset(reset),
             .nicEn(node3_nicEn),
             .nicEnWr(node3_nicWrEn),
             .d_in(node3_din_nic),
             .d_out(node3_dout_nic),
             .addr(node3_addr_nic),
             .net_so(node3_net_so),
             .net_ro(node3_net_ro),
             .net_do(node3_net_do),
             .net_polarity(node3_net_polarity),
             .net_si(node3_net_si),
             .net_ri(node3_net_ri),
             .net_di(node3_net_di));
   
   // Instantiate ring
	gold_ring gold_ring_0 (
		.clk(clk), .reset(reset), 
		// ports on router 0
		.node0_pesi(node0_net_so),
		.node0_pedi(node0_net_do),
		.node0_peri(node0_net_ro),
		.node0_peso(node0_net_si),
		.node0_pero(node0_net_ri),
		.node0_pedo(node0_net_di),
		.node0_polarity(node0_net_polarity),
		// ports on router 1
		.node1_pesi(node1_net_so),
		.node1_pedi(node1_net_do),
		.node1_peri(node1_net_ro),
		.node1_peso(node1_net_si),
		.node1_pero(node1_net_ri),
		.node1_pedo(node1_net_di),
		.node1_polarity(node1_net_polarity),
		// ports on router 2
		.node2_pesi(node2_net_so),
		.node2_pedi(node2_net_do),
		.node2_peri(node2_net_ro),
		.node2_peso(node2_net_si),
		.node2_pero(node2_net_ri),
		.node2_pedo(node2_net_di),
		.node2_polarity(node2_net_polarity),
		// ports on router 3
		.node3_pesi(node3_net_so),
		.node3_pedi(node3_net_do),
		.node3_peri(node3_net_ro),
		.node3_peso(node3_net_si),
		.node3_pero(node3_net_ri),
		.node3_pedo(node3_net_di),
		.node3_polarity(node3_net_polarity)
	);
   
endmodule