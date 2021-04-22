// Testbench for the Processor RTL Verification
`timescale 1ns/10ps

// Define Clock cycle, using 250MHz.
`define CYCLE_TIME 4

// Include Files

// Memory Files
`include "./include/dmem.v"
`include "./include/imem.v"
// `include "./include/gscl45nm.v"

// CPU Files
// Include all your proces design files here
// `include "./design/cpu.v"
//`include "cpu.v"
// `include "NIC.v"

module cpu_tb;
	reg CLK, RESET;
	wire [0:31] ProgramCounter;  // PC output from processor
	wire [0:31] Instruction;     // Instruction from IMEM to processor
	wire [0:63] DataIn;          // Data into the processor from DMEM
	wire [0:63] DataOut;         // Data write to DMEM
	wire  MemEn, MemWrEn;        // DMEM control signals
	wire [0:31] MemAddr;         // DMEM read/write address
	
	wire [0:1] Addr_Nic;         //Addr port for NIC
	wire [0:63] Din_Nic,Dout_Nic;//Data port for NIC
	wire NicEn,NicWrEn;          //Enable signals for NIC
	
	integer CycleNum;            // Counter to count number of cycles for program exec.

	integer i;
	integer dmem_dump_file;

	// // NIC Instance
	// NIC nic (.addr(Addr_Nic), .d_in(Din_Nic), .d_out(Dout_Nic), .nicEn(NicEn), .nicEnWr(NicWrEn), 
	// 			.net_si(), .net_ri(), .net_di(), .net_so(), .net_ro(), .net_do(),
	// 			.net_polarity(), .clk(), .reset());

	// Instruction Memory Instance
	imem IM (
		.memAddr (ProgramCounter[22:29]),  // Memory Read Address (8-bit)
		.dataOut (Instruction)	           // Memory READ Output data
	);

	// Data Memory Instance
	dmem DM (
		.clk      (CLK),               // System Clock
		.memEn    (MemEn),             // Memory Enable
		.memWrEn  (MemWrEn),           // Memory Write Enable
		.memAddr  (MemAddr[24:31]),    // Memory Address (8-bit)
		.dataIn   (DataOut),           // Memory WRITE Data  (input to data-memory)
		.dataOut  (DataIn)             // Memory READ Data (output from data-memory)
	);

	// Processor Instance
	
 cardinal_cpu cpu   (.clk(CLK),               //System Clock
					 .reset(RESET),           // System Reset
					 .inst_in(Instruction),   //Instruction from the Instruction Memory
					 .d_in(DataIn),           // Data from Data Memory
					 .pc_out(ProgramCounter), // Program Counter
					 .d_out(DataOut),         // Write Data to Data Memory
					 .addr_out(MemAddr),      // Write Address for Data Memory
					 .memWrEn(MemWrEn),       // Data Memory Write Enable
					 .memEn(MemEn),           // Data Memory Enable
					 .addr_nic(Addr_Nic),     //Address bits for the NIC interface
					 .din_nic(Din_Nic),       //Data flowing from Processor to NIC
					 .dout_nic(Dout_Nic),     //Data flowing from NIC to Processor 
					 .nicEn(NicEn),           //Enable signal for NIC
					 .nicWrEn(NicWrEn));      //Enable Write signal for NIC

	// Clock Generation
	always #(`CYCLE_TIME /2) CLK <= ~CLK;

	// Cycle Counter
	always @(posedge CLK) begin
		if(RESET)
			CycleNum <= 'd0;
		else
			CycleNum <= CycleNum + 'd1;
	end

	integer ofd;
	// Initial
	initial begin

		ofd = $fopen("cpu.control", "w");
		$fmonitor(ofd, "CycleNum = %d,  
						
						   r0_data_out = %h, r1_data_out = %h, ALU_op0 = %h, ALU_op1 = %h, r1_data_EXMEM = %h, func_IFID = %b, func_EXMEM = %b, ALU_out_EXMEM = %h, ALU_out_EXMEMWB = %h,
							\n", 
						CycleNum,  
						cpu.r0_data_out, cpu.r1_data_out,
						cpu.ALU_op0, cpu.ALU_op1, cpu.r1_data_EXMEM,  cpu.func_IFID, cpu.func_EXMEM, cpu.ALU_out_EXMEM, cpu.ALU_out_EXMEMWB,
						);
		$readmemh("imem.fill", IM.MEM);    // Loading Instruction Memory
		$readmemh("dmem.fill", DM.MEM);    // Loading Data Memory
		CLK <= 0;                          // Initialize Clock
		CycleNum <= 0;                     // Initialize
		RESET <= 1'b1;                     // Reset the CPU
		repeat (6) @(negedge CLK);         // Wait for CPU
		RESET <= 1'b0;                     // de-activate reset signal



		// Convention for LAST INSTRUCTION
		// We would have a last Instruction NOP  => 32'h00000000
		wait(Instruction == 32'h00000000);

		//Let us see how many cycles your program took
		$display ("The Program Completed in %d cycles", CycleNum);

		// Let us now flush the pipeline
		repeat(5) @(negedge CLK);

		// Open file to copy contents of data-memory
		dmem_dump_file = $fopen("dmem.dump");

		// Dump all locations of data-memory to output file
		for (i=0; i<128;i=i+1) begin
			
			$fdisplay(dmem_dump_file, "Memory Location #%3d: %h" , i, DM.MEM[i]);
		end
		$display("i = %d, DM.MEM[i] = %h", 120, DM.MEM[120]);

		$fclose(dmem_dump_file);
		$stop;


	end	// initial block ends here

endmodule
