//`include "/usr/local/synopsys/Design_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW01_add.v"
//`include "./include/DW_div.v"
`include "/usr/local/synopsys/DFT_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW_sqrt_pipe.v"


module DW_sqrt_inst (clk, rst_n, en, a, root);

  parameter width    = 8;

  input clk, rst_n, en;
  input  [width-1 : 0] a;
  output [((width+1)/2)-1 : 0] root;

  // Please add +incdir+$SYNOPSYS/dw/sim_ver+ to your verilog simulator
  // command line (for simulation).

  // instance of DW_sqrt_pipe
  DW_sqrt_pipe #(.width(width)) DW_sqrt_0 (.clk(clk) , .rst_n(rst_n) , .en(en) , .a(a) , .root(root));

endmodule
