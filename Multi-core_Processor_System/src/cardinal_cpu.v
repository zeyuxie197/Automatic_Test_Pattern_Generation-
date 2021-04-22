/* Author: Zeyu Xie 4/3/2021
   Four stages pipelined cpu 
   1. IF-stage 2. ID-stage 3. EX/MEM-stage 4. WB-stage
*/


`include "register_file.v"
`include "alu.v"

module cardinal_cpu (   input clk,               //System Clock
					input reset,            // System Reset
					input [0:31]inst_in,          //Instruction from the Instruction Memory
					input [0:63] d_in,             // Data from Data Memory
					output reg [0:31] pc_out,            // Program Counter
					output [0:63] d_out,            // Write Data to Data Memory
					output [0:31] addr_out,         // Write Address for Data Memory
					output  memWrEn,          // Data Memory Write Enable
					output  memEn,            // Data Memory Enable
					output [0:1] addr_nic,         //Address bits for the NIC interface
					output [0:63] din_nic,          //Data flowing from Processor to NIC
					input [0:63] dout_nic,         //Data flowing from NIC to Processor 
					output  nicEn,            //Enable signal for NIC
					output  nicWrEn);         //Enable Write signal for NIC

   

   // stall control for ALU, assume stall_ALU is the control signal
   wire stall_ALU;
   wire stall_MEM;
   reg stall_BEQ;
   wire MemRead_EXMEM_wire, MemWrite_EXMEM_wire, memorNIC_EXMEM;
   wire nicEn_wire, nicWrEn_wire;
   
   assign memEn = ~stall_ALU && MemRead_EXMEM_wire;
   assign memWrEn = ~stall_ALU && MemWrite_EXMEM_wire;
   assign nicEn = ~stall_ALU && nicEn_wire;
   assign nicWrEn = ~stall_ALU && nicWrEn_wire;
   
   // final stall signal
   wire stall;

   assign stall = stall_ALU || stall_BEQ || stall_MEM;

   
   

   //-------------------------------------------------------------------------------------------------------------------------------------
   // IF_stage
   // Program Counter
   // reg [0:31] pc_out; 
   wire [0:31] PC_in; // input of pc_out counter
   wire en_PC;

   assign en_PC = ~stall;

   always @(posedge clk) begin
      if (reset) begin
         pc_out <= 0; // reset to 32'h0;
      end
      else begin
         if (en_PC) begin
            pc_out <= PC_in;
         end
         else pc_out <= pc_out;
      end
   end

   // pc_out increments by 4 every clk except beq successfully
   wire [0:31] PC_add4;
   wire [0:31] Bran_addr;
   reg Bran_suc;
   assign PC_add4 = pc_out + 4; 
   assign PC_in = Bran_suc ? Bran_addr : PC_add4; // Mux
   
   // Instruction memory
   // wire [0:31] inst_in; // input from imem
   
   // IF/ID register
   reg [0:5] opcode_IFID;
   reg [0:4] rd_addr_IFID;
   reg [0:4] rs_addr_IFID;
   reg [0:4] rt_addr_IFID;
   reg [0:4] width_IFID; // decide the width of data such as byte, half word
   reg [0:5] func_IFID;
   reg [0:15] bran_addr_IFID;
   reg flush_IFID;
   wire en_IFID;

   assign en_IFID = ~stall;

   always @(posedge clk) begin
      if (reset) begin
         opcode_IFID <= 0;
         rd_addr_IFID <= 0;
         rs_addr_IFID <= 0;
         rt_addr_IFID <= 0;
         width_IFID <= 0;
         func_IFID <= 0;
      end
      else begin
         flush_IFID <= Bran_suc; // flush if beq successes
         if (en_IFID) begin
            opcode_IFID <= inst_in[0:5];
            rd_addr_IFID <= inst_in[6+:5];
            rs_addr_IFID <= inst_in[11+:5];
            rt_addr_IFID <= inst_in[16+:5];
            width_IFID <= inst_in[21+:5];
            func_IFID <= inst_in[26+:6];
            bran_addr_IFID <= inst_in[16+:16];
         end
      end
   end

   //------------------------------------------------------------------------------------------------------------------------------
   // ID_stage
   // register file
   wire RegWrite_WB;
   wire [0:63] REG_data_WB;
   wire [0:4] rd_addr_WB;

   reg Reg_sel; // select if read rd or rt depending on beq
   wire [0:4] rd_addr_ID;
   wire [0:4] rs_addr_ID;
   wire [0:4] rt_addr_ID;
   wire [0:4] r1_addr_ID;
   wire [0:63] r0_data_out, r1_data_out;

   assign rd_addr_ID = rd_addr_IFID;
   assign rs_addr_ID = rs_addr_IFID;
   assign rt_addr_ID = rt_addr_IFID;
   
   register_file register_file0(.clk(clk), .reset(reset), .wr_en(RegWrite_WB), .wr_data_in(REG_data_WB),
                                 .wr_addr_in(rd_addr_WB), .re_addr_in0(rs_addr_ID), .re_addr_in1(r1_addr_ID),
                                 .re_data_out0(r0_data_out), .re_data_out1(r1_data_out));

   
   // decode opcode
   wire [0:5] opcode_ID;
   
   assign opcode_ID = opcode_IFID;

   wire [0:5] opsel1_ID;
   wire [0:5] opsel2_ID;
   wire flush_ID;
   
   assign flush_ID = flush_IFID;

   always @(*) begin
      if ((opsel1_ID == 6'b100010) || (opsel1_ID == 6'b100011) || opsel1_ID == 6'b100000 || opsel1_ID == 6'b100001) begin
         Reg_sel = 1;
      end
      else Reg_sel = 0;
   end

   assign r1_addr_ID = Reg_sel ? rd_addr_ID : rt_addr_ID; // if beq operation, regfile will read rd instead of rt;

   assign opsel1_ID = flush_ID ? 6'b000000 : opcode_ID;
   assign opsel2_ID = stall_BEQ ? 6'b000000 : opsel1_ID;

   // combinational logic of branch instruction check
   always @(*) begin
      if (((opsel1_ID == 6'b100010) && (r1_data_out == 0)) 
         || ((opsel1_ID == 6'b100011) && (r1_data_out != 0))) begin // beq logic and bneq logic       
         Bran_suc = 1;
      end
      else begin
         Bran_suc = 0;
      end
   end

   // branch address output to IF stage
   wire [0:15] bran_addr_ID; // input from IF stage
   wire [0:31] bran_addr_ID_out; // output in ID stage

   assign bran_addr_ID = bran_addr_IFID;
   assign bran_addr_ID_out = {{14{1'b0}}, bran_addr_ID, 2'b00}; // branch address back to IF stage
   assign Bran_addr = bran_addr_ID_out;

   // control signal for ID/EXMEM stage
   reg R_type_flag; // check if it is R-type instruction
   reg RegWrite_IDEXMEM;
   reg MemtoReg_IDEXMEM;
   reg MemRead_IDEXMEM;
   reg MemWrite_IDEXMEM;
   reg memorNIC_IDEXMEM;

   // control signal for NIC
   reg nicEn_IDEXMEM;
   reg nicWrEn_IDEXMEM;
   reg stall_MEM_REG;

   // control signal for data memory and NIC
   wire en_IDEXMEM;
   assign en_IDEXMEM = ~(stall_ALU || stall_MEM);

   always @(posedge clk) begin
      if (reset) begin
         MemRead_IDEXMEM <= 0;
         MemWrite_IDEXMEM <= 0;
         nicEn_IDEXMEM <= 0;
         nicWrEn_IDEXMEM <= 0;
         memorNIC_IDEXMEM <= 0;
         stall_MEM_REG <= 0;
      end
      else begin
         if (en_IDEXMEM) begin
            stall_MEM_REG <= 0;
            MemRead_IDEXMEM <= 0;
            MemWrite_IDEXMEM <= 0;
            nicEn_IDEXMEM <= 0;
            nicWrEn_IDEXMEM <= 0;
            memorNIC_IDEXMEM <= 0;
            case (opsel2_ID) 
               6'b100000: begin
                  stall_MEM_REG <= 1;
                  if (bran_addr_ID[0] == 0 && bran_addr_ID[1] == 0) begin // load data from data memory instruction
                     MemRead_IDEXMEM <= 1;
                     MemWrite_IDEXMEM <= 0;
                     nicEn_IDEXMEM <= 0;
                     nicWrEn_IDEXMEM <= 0;
                     memorNIC_IDEXMEM <= 1;
                  end
                  else begin // load data from NIC
                     nicEn_IDEXMEM <= 1;
                     nicWrEn_IDEXMEM <= 0;
                     MemRead_IDEXMEM <= 0;
                     MemWrite_IDEXMEM <= 0;
                     memorNIC_IDEXMEM <= 0;
                  end
               end
               6'b100001: begin
                  stall_MEM_REG <= 1; 
                  if (bran_addr_ID[0] == 0 && bran_addr_ID[1] == 0) begin // store data into data memory instruction
                     MemRead_IDEXMEM <= 1;
                     MemWrite_IDEXMEM <= 1;
                     nicEn_IDEXMEM <= 0;
                     nicWrEn_IDEXMEM <= 0;
                     memorNIC_IDEXMEM <= 1;
                  end
                  else begin // store data into NIC
                     nicEn_IDEXMEM <= 1;
                     nicWrEn_IDEXMEM <= 1;
                     MemRead_IDEXMEM <= 0;
                     MemWrite_IDEXMEM <= 0;
                     memorNIC_IDEXMEM <= 0;
                  end
               end
            endcase
         end
      end
      
   end
   
   // control signal in ID/EXMEM register
   always @(posedge clk) begin
      if (reset) begin
         R_type_flag <= 0;
         RegWrite_IDEXMEM <= 0;      
         MemtoReg_IDEXMEM <= 0;
      end
      else begin
         if (en_IDEXMEM) begin
            case (opsel2_ID) 
               6'b101010: begin // R-type instruction
                  R_type_flag <= 1;
                  RegWrite_IDEXMEM <= 1;            
                  MemtoReg_IDEXMEM <= 0;
               end
               6'b100000: begin // load data from data memory instruction
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 1;        
                  MemtoReg_IDEXMEM <= 1;
               end
               6'b100001: begin // store data into data memory instruction
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 0;
                  MemtoReg_IDEXMEM <= 0; // do not care
               end
               6'b100010: begin // branch equal instruction
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 0;                  
                  MemtoReg_IDEXMEM <= 0;
               end
               6'b100011: begin // branch not equal instruction
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 0;
                  MemtoReg_IDEXMEM <= 0;
               end
               6'b111100: begin // NOP
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 0;
                  MemtoReg_IDEXMEM <= 0;
               end
               6'b000000: begin // NOP
                  R_type_flag <= 0;
                  RegWrite_IDEXMEM <= 0;
                  MemtoReg_IDEXMEM <= 0;
               end
            endcase
         end
      end
      
   end

   //ID/EXMEM register
   wire [0:4] width_ID;
   wire [0:5] func_ID;
   assign width_ID = width_IFID;
   assign func_ID = func_IFID;

   reg [0:63] r0_data_IDEXMEM;
   reg [0:63] r1_data_IDEXMEM;
   reg [0:4] rd_addr_IDEXMEM, rs_addr_IDEXMEM, rt_addr_IDEXMEM;
   reg [0:4] width_IDEXMEM;
   reg [0:5] func_IDEXMEM;
   reg [0:31] immedia_IDEXMEM;

   always @(posedge clk) begin
      if (reset) begin
         r0_data_IDEXMEM <= 0;
         r1_data_IDEXMEM <= 0;
         rd_addr_IDEXMEM <= 0;
         width_IDEXMEM <= 0;
         func_IDEXMEM <= 0;
         rs_addr_IDEXMEM <= 0;
         rt_addr_IDEXMEM <= 0;
         immedia_IDEXMEM <= 0; // address for load and store operation
      end
      else begin
         if (en_IDEXMEM) begin
            r0_data_IDEXMEM <= r0_data_out;
            r1_data_IDEXMEM <= r1_data_out;
            rd_addr_IDEXMEM <= rd_addr_ID;
            width_IDEXMEM <= width_ID;
            func_IDEXMEM <= func_ID;
            rs_addr_IDEXMEM <= rs_addr_ID;
            rt_addr_IDEXMEM <= rt_addr_ID;
            immedia_IDEXMEM <= {16'h0000, bran_addr_ID};
         end
      end
   end

   //------------------------------------------------------------------------------------------------------------------------------------------
   // EXMEM_stage
   // logic for data memory and NIC
   wire stall_MEM_wire;
   reg mem_counter;

   // stall one clock for lw and sw
   always @(posedge clk) begin
		if (reset) 
			mem_counter <= 0;
		else begin
			if (stall_MEM_wire)  begin  
				if(mem_counter == 1)
					mem_counter <= 0;
				else mem_counter <= mem_counter + 1;
			end
		end
	end

   assign stall_MEM = stall_MEM_wire && ~mem_counter;

   // interaction between ID and EXMEM
   assign addr_out = immedia_IDEXMEM;
   assign addr_nic = {immedia_IDEXMEM[30], immedia_IDEXMEM[31]};
   assign d_out = r1_data_IDEXMEM;
   assign din_nic = r1_data_IDEXMEM;
   assign nicEn_wire = nicEn_IDEXMEM;
   assign nicWrEn_wire = nicWrEn_IDEXMEM;
   assign MemRead_EXMEM_wire = MemRead_IDEXMEM;
   assign MemWrite_EXMEM_wire = MemWrite_IDEXMEM;
   assign stall_MEM_wire = stall_MEM_REG;

	//read the ID/EXMEM stage register
	wire [0:63] r0_data_EXMEM,r1_data_EXMEM;
	wire [0:4] rs_addr_EXMEM,rt_addr_EXMEM,rd_addr_EXMEM, width_EXMEM;
	wire [0:5] func_EXMEM;
	wire RegWrite_EXMEM,MemtoReg_EXMEM;
	
	assign r0_data_EXMEM = r0_data_IDEXMEM;
	assign r1_data_EXMEM = r1_data_IDEXMEM;
	assign rs_addr_EXMEM = rs_addr_IDEXMEM;
	assign rt_addr_EXMEM = rt_addr_IDEXMEM;
	assign rd_addr_EXMEM = rd_addr_IDEXMEM;
	assign width_EXMEM   = width_IDEXMEM;
	assign func_EXMEM    = func_IDEXMEM;
	assign RegWrite_EXMEM= RegWrite_IDEXMEM;
	assign MemtoReg_EXMEM= MemtoReg_IDEXMEM;
	assign memorNIC_EXMEM= memorNIC_IDEXMEM;
	
	// mux to select the data from NIC or mem   
	wire [0:63] mem_data_EXMEM;
	assign mem_data_EXMEM = memorNIC_EXMEM ? d_in : dout_nic;
	
	//ALU and input mux of ALU
	wire [0:63] ALU_op0,ALU_op1,ALU_out_EXMEM;
	wire FW0_WB_EXMEM,FW1_WB_EXMEM;   //forwarding signals 

	assign ALU_op0 = (FW0_WB_EXMEM) ? REG_data_WB : r0_data_EXMEM;
	assign ALU_op1 = (FW1_WB_EXMEM) ? REG_data_WB : r1_data_EXMEM;
		
	alu alu_0 (
		.opA(ALU_op0), .opB(ALU_op1), .opcode(func_EXMEM),
		.wordwidth(width_EXMEM[3:4]), .dout(ALU_out_EXMEM)
	);	
	
	//generate the stall_ALU
	//stall 5 clk for MUL, shift, sQ, DIV, MOD, SQRT
	reg [0:2] counter_stall;
	wire stall_ALU_temp;  
	
	assign stall_ALU_temp = R_type_flag && ((func_EXMEM[1] ==1) || (func_EXMEM[2] == 1));   
    
	always @(posedge clk) begin
		if (reset) 
			counter_stall <= 0;
		else begin
			if (stall_ALU_temp)  begin  
				if(counter_stall == 4)
					counter_stall <= 0;
				else counter_stall <= counter_stall + 1;
			end
		end
	end
	
	assign stall_ALU = ((stall_ALU_temp) && ( ~counter_stall[0])) ? 1 : 0;

	//EXMEM/WB stage register
	reg MemtoReg_EXMEMWB,RegWrite_EXMEMWB;
	reg [0:63] ALU_out_EXMEMWB,mem_data_EXMEMWB;
	reg [0:4] rd_addr_EXMEMWB;
	
	always @(posedge clk) begin
		if (reset) begin
			MemtoReg_EXMEMWB <= 0;
			RegWrite_EXMEMWB <= 0;
			ALU_out_EXMEMWB  <= 0;
			mem_data_EXMEMWB<= 0;
			rd_addr_EXMEMWB  <= 0;
		end
		else begin
			if (~ (stall_ALU || stall_MEM)) begin
				MemtoReg_EXMEMWB <= MemtoReg_EXMEM;
				RegWrite_EXMEMWB <= RegWrite_EXMEM;
				ALU_out_EXMEMWB  <= ALU_out_EXMEM;
				mem_data_EXMEMWB <= mem_data_EXMEM;
				rd_addr_EXMEMWB  <= rd_addr_EXMEM;
			end
			else begin
				MemtoReg_EXMEMWB <= MemtoReg_EXMEMWB;
				RegWrite_EXMEMWB <= RegWrite_EXMEMWB;
				ALU_out_EXMEMWB  <= ALU_out_EXMEMWB;
				mem_data_EXMEMWB <= mem_data_EXMEMWB;
				rd_addr_EXMEMWB  <= rd_addr_EXMEMWB;
			end			
		end
	end   
    
	//read the EXMEM/WB stage register
	wire MemtoReg_WB;
	//wire [0:4] rd_addr_WB;
	wire [0:63] mem_data_WB,ALU_out_WB;
	
	assign RegWrite_WB = RegWrite_EXMEMWB;
	assign MemtoReg_WB = MemtoReg_EXMEMWB;
	assign rd_addr_WB  = rd_addr_EXMEMWB;
	assign mem_data_WB = mem_data_EXMEMWB;
	assign ALU_out_WB  = ALU_out_EXMEMWB;
	
	//WB stage
	assign REG_data_WB = MemtoReg_WB ? mem_data_WB : ALU_out_WB;
   
	//fowarding unit
	assign FW0_WB_EXMEM = ( (rs_addr_EXMEM == rd_addr_WB) && R_type_flag && RegWrite_WB ) ? 1 : 0;
	assign FW1_WB_EXMEM = ( (rt_addr_EXMEM == rd_addr_WB) && R_type_flag && RegWrite_WB ) ? 1 : 0;
   
   // hazard detection unit for branch
   always @(*) begin
      if ((opsel1_ID == 6'b100010 || opsel1_ID == 6'b100011) && 
         (RegWrite_EXMEM && (rd_addr_EXMEM != 0) && (rd_addr_ID == rd_addr_EXMEM))) begin
         stall_BEQ <= 1;
      end
      else stall_BEQ <= 0;
   end

endmodule

