//`include "./include/sim_ver/DW_div.v"
//`include "./include/sim_ver/DW_sqrt.v"

`include "/usr/local/synopsys/Design_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW_div.v"
`include "/usr/local/synopsys/Design_Compiler/K-2015.06-SP5-5/dw/sim_ver/DW_sqrt.v"
module alu (opA,opB,opcode,wordwidth,dout
);
	input [0:63] opA,opB;
	input [0:5] opcode;
	input [0:1] wordwidth;
	output [0:63] dout;
	
	localparam  VAND   = 6'b000001,
				VOR    = 6'b000010,
				VXOR   = 6'b000011,
				VNOT   = 6'b000100,
				VMOV   = 6'b000101,
				VADD   = 6'b000110,
				VSUB   = 6'b000111,
				VMULEU = 6'b001000,
				VMULOU = 6'b001001,
				VSLL   = 6'b001010,
				VSRL   = 6'b001011,
				VSRA   = 6'b001100,
				VRTTH  = 6'b001101,
				VDIV   = 6'b001110,
				VMOD   = 6'b001111,
				VSQEU  = 6'b010000,
				VSQOU  = 6'b010001,
				VSQRT  = 6'b010010;
	
	localparam  ModeB = 2'b00,  //byte mode
				ModeH = 2'b01,  //half word mode
				ModeW = 2'b10,  //word mode
				ModeD = 2'b11;  //double word mode

//----------------------------------------------------------------------------
//VADD operation
	reg [0:63]sum;
	
	always @(*) begin
		sum = 64'bx;
		if (opcode == VADD) begin
			case (wordwidth)
			
				ModeB: begin
					sum[0:7]   = opA[0:7] + opB[0:7];
					sum[8:15]  = opA[8:15] + opB[8:15];
					sum[16:23] = opA[16:23] + opB[16:23];
					sum[24:31] = opA[24:31] + opB[24:31];
					sum[32:39] = opA[32:39] + opB[32:39];
					sum[40:47] = opA[40:47] + opB[40:47];
					sum[48:55] = opA[48:55] + opB[48:55];
					sum[56:63] = opA[56:63] + opB[56:63];
				end
				
				ModeH: begin
					sum[0:15]  = opA[0:15] + opB[0:15];
					sum[16:31] = opA[16:31] + opB[16:31];
					sum[32:47] = opA[32:47] + opB[32:47];
					sum[48:63] = opA[48:63] + opB[48:63];
				end
				
				ModeW: begin
					sum[0:31]  = opA[0:31] + opB[0:31];
					sum[32:63] = opA[32:63] + opB[32:63];
				end
				
				ModeD: sum = opA + opB;
				
			endcase
		end
	end


//----------------------------------------------------------------------------
//VSUB operation
	reg [0:63]difference;
	
	always @(*) begin
		difference = 64'bx;
		if (opcode == VSUB) begin
			case (wordwidth)
			
				ModeB: begin
					difference[0:7]   = opA[0:7] + ~opB[0:7] + 1;
					difference[8:15]  = opA[8:15] + ~opB[8:15] + 1;
					difference[16:23] = opA[16:23] + ~opB[16:23] + 1;
					difference[24:31] = opA[24:31] + ~opB[24:31] + 1;
					difference[32:39] = opA[32:39] + ~opB[32:39] + 1;
					difference[40:47] = opA[40:47] + ~opB[40:47] + 1;
					difference[48:55] = opA[48:55] + ~opB[48:55] + 1;
					difference[56:63] = opA[56:63] + ~opB[56:63] + 1;
				end
				
				ModeH: begin
					difference[0:15]  = opA[0:15] + ~opB[0:15] + 1;
					difference[16:31] = opA[16:31] + ~opB[16:31] + 1;
					difference[32:47] = opA[32:47] + ~opB[32:47] + 1;
					difference[48:63] = opA[48:63] + ~opB[48:63] + 1;
				end
				
				ModeW: begin
					difference[0:31]  = opA[0:31] + ~opB[0:31] + 1;
					difference[32:63] = opA[32:63] + ~opB[32:63] + 1;
				end
				
				ModeD: difference = opA + ~opB + 1;
				
			endcase
		end
	end

					
//----------------------------------------------------------------------------
//VMULEU,VMULOU,VSQEU,VSQOU operation
	reg [0:63]product_eu, product_ou;
	reg [0:63]MulopA, MulopB;  //two factors of multiplication
	always @(*) begin
		MulopA = opA;
		MulopB = 64'bx;
		if ((opcode == VMULEU) || (opcode == VMULOU))  //the second factor is opB when doing multiplication
			MulopB = opB;
		else if ((opcode == VSQEU) || (opcode == VSQOU))  //the second factor is opA when doing squaring
			MulopB = opA;
	end
	
	always @(*) begin
		product_eu = 64'bx;
		if ((opcode == VMULEU) || (opcode == VSQEU)) begin
			case (wordwidth)
				
				ModeB: begin
					product_eu[0:15]  = MulopA[0:7] * MulopB[0:7];
					product_eu[16:31] = MulopA[16:23] * MulopB[16:23];
					product_eu[32:47] = MulopA[32:39] * MulopB[32:39];
					product_eu[48:63] = MulopA[48:55] * MulopB[48:55];
				end
				
				ModeH: begin
					product_eu[0:31]  = MulopA[0:15] * MulopB[0:15];
					product_eu[32:63] = MulopA[32:47] * MulopB[32:47];
				end
				
				ModeW: product_eu[0:63] = MulopA[0:31] * MulopB[0:31];
				
			endcase
		end
	end
	
	always @(*) begin
		product_ou = 64'bx;
		if ((opcode == VMULOU) || (opcode == VSQOU)) begin
			case (wordwidth)
				
				ModeB: begin
					product_ou[0:15]  = MulopA[8:15] * MulopB[8:15];
					product_ou[16:31] = MulopA[24:31] * MulopB[24:31];
					product_ou[32:47] = MulopA[40:47] * MulopB[40:47];
					product_ou[48:63] = MulopA[56:63] * MulopB[56:63];
				end
				
				ModeH: begin
					product_ou[0:31]  = MulopA[16:31] * MulopB[16:31];
					product_ou[32:63] = MulopA[48:63] * MulopB[48:63];
				end
				
				ModeW: product_ou[0:63] = MulopA[32:63] * MulopB[32:63];
				
			endcase
		end
	end				
					
					
//----------------------------------------------------------------------------
//VSLL operation
	reg [0:63]Data_SLL;
	reg [0:5] SLL_value;
	
	always @(*) begin
		Data_SLL = 64'bx;
		SLL_value = 6'bx;
		if (opcode == VSLL) begin
			case (wordwidth)
			
				ModeB: begin
					SLL_value = {3'b000, opB[5:7]};
					Data_SLL[0:7] = opA[0:7] << SLL_value;
					SLL_value = {3'b000, opB[13:15]};
					Data_SLL[8:15] = opA[8:15] << SLL_value;
					SLL_value = {3'b000, opB[21:23]};
					Data_SLL[16:23] = opA[16:23] << SLL_value;
					SLL_value = {3'b000, opB[29:31]};
					Data_SLL[24:31] = opA[23:31] << SLL_value;
					SLL_value = {3'b000, opB[37:39]};
					Data_SLL[32:39] = opA[32:39] << SLL_value;
					SLL_value = {3'b000, opB[45:47]};
					Data_SLL[40:47] = opA[40:47] << SLL_value;
					SLL_value = {3'b000, opB[53:55]};
					Data_SLL[48:55] = opA[48:55] << SLL_value;
					SLL_value = {3'b000, opB[61:63]};
					Data_SLL[56:63] = opA[56:63] << SLL_value;					
				end
				
				ModeH: begin
					SLL_value = {2'b00, opB[12:15]};
					Data_SLL[0:15] = opA[0:15] << SLL_value;
					SLL_value = {2'b00, opB[28:31]};
					Data_SLL[16:31] = opA[16:31] << SLL_value;
					SLL_value = {2'b00, opB[44:47]};
					Data_SLL[32:47] = opA[32:47] << SLL_value;
					SLL_value = {2'b00, opB[60:63]};
					Data_SLL[48:63] = opA[48:63] << SLL_value;
				end
				
				ModeW: begin
					SLL_value = {1'b0, opB[27:31]};
					Data_SLL[0:31] = opA[0:31] << SLL_value;
					SLL_value = {1'b0, opB[59:63]};
					Data_SLL[32:63] = opA[0:31] << SLL_value;
				end
				
				ModeD: begin
					SLL_value = opB[58:63];
					Data_SLL = opA << SLL_value;	
				end
				
			endcase
		end
	end


//----------------------------------------------------------------------------
//VSRL operation
	reg [0:63]Data_SRL;
	reg [0:5] SRL_value;	
	
	always @(*) begin
		Data_SRL = 64'bx;
		SRL_value = 6'bx;
		if (opcode == VSRL) begin
			case (wordwidth)
			
				ModeB: begin
					SRL_value = {3'b000, opB[5:7]};
					Data_SRL[0:7] = opA[0:7] >> SRL_value;
					SRL_value = {3'b000, opB[13:15]};
					Data_SRL[8:15] = opA[8:15] >> SRL_value;
					SRL_value = {3'b000, opB[21:23]};
					Data_SRL[16:23] = opA[16:23] >> SRL_value;
					SRL_value = {3'b000, opB[29:31]};
					Data_SRL[24:31] = opA[23:31] >> SRL_value;
					SRL_value = {3'b000, opB[37:39]};
					Data_SRL[32:39] = opA[32:39] >> SRL_value;
					SRL_value = {3'b000, opB[45:47]};
					Data_SRL[40:47] = opA[40:47] >> SRL_value;
					SRL_value = {3'b000, opB[53:55]};
					Data_SRL[48:55] = opA[48:55] >> SRL_value;
					SRL_value = {3'b000, opB[61:63]};
					Data_SRL[56:63] = opA[56:63] >> SRL_value;					
				end
				
				ModeH: begin
					SRL_value = {2'b00, opB[12:15]};
					Data_SRL[0:15] = opA[0:15] >> SRL_value;
					SRL_value = {2'b00, opB[28:31]};
					Data_SRL[16:31] = opA[16:31] >> SRL_value;
					SRL_value = {2'b00, opB[44:47]};
					Data_SRL[32:47] = opA[32:47] >> SRL_value;
					SRL_value = {2'b00, opB[60:63]};
					Data_SRL[48:63] = opA[48:63] >> SRL_value;
				end
				
				ModeW: begin
					SRL_value = {1'b0, opB[27:31]};
					Data_SRL[0:31] = opA[0:31] >> SRL_value;
					SRL_value = {1'b0, opB[59:63]};
					Data_SRL[32:63] = opA[0:31] >> SRL_value;
				end
				
				ModeD: begin
					SRL_value = opB[58:63];
					Data_SRL = opA >> SRL_value;	
				end
				
			endcase
		end
	end


//----------------------------------------------------------------------------
//VSRA operation
	reg [0:63]Data_SRA;
	reg [0:5] SRA_value;
	
	always @(*) begin
		Data_SRA = 64'bx;
		SRA_value = 6'bx;
		if (opcode == VSRA) begin
			case (wordwidth)
			
				ModeB: begin
					SRA_value = {3'b000, opB[5:7]};
					Data_SRA[0:7] = $signed(opA[0:7]) >>> SRA_value;
					SRA_value = {3'b000, opB[13:15]};
					Data_SRA[8:15] = $signed(opA[8:15]) >>> SRA_value;
					SRA_value = {3'b000, opB[21:23]};
					Data_SRA[16:23] = $signed(opA[16:23]) >>> SRA_value;
					SRA_value = {3'b000, opB[29:31]};
					Data_SRA[24:31] = $signed(opA[23:31]) >>> SRA_value;
					SRA_value = {3'b000, opB[37:39]};
					Data_SRA[32:39] = $signed(opA[32:39]) >>> SRA_value;
					SRA_value = {3'b000, opB[45:47]};
					Data_SRA[40:47] = $signed(opA[40:47]) >>> SRA_value;
					SRA_value = {3'b000, opB[53:55]};
					Data_SRA[48:55] = $signed(opA[48:55]) >>> SRA_value;
					SRA_value = {3'b000, opB[61:63]};
					Data_SRA[56:63] = $signed(opA[56:63]) >>> SRA_value;					
				end
				
				ModeH: begin
					SRA_value = {2'b00, opB[12:15]};
					Data_SRA[0:15] = $signed(opA[0:15]) >>> SRA_value;
					SRA_value = {2'b00, opB[28:31]};
					Data_SRA[16:31] = $signed(opA[16:31]) >>> SRA_value;
					SRA_value = {2'b00, opB[44:47]};
					Data_SRA[32:47] = $signed(opA[32:47]) >>> SRA_value;
					SRA_value = {2'b00, opB[60:63]};
					Data_SRA[48:63] = $signed(opA[48:63]) >>> SRA_value;
				end
				
				ModeW: begin
					SRA_value = {1'b0, opB[27:31]};
					Data_SRA[0:31] = $signed(opA[0:31]) >>> SRA_value;
					SRA_value = {1'b0, opB[59:63]};
					Data_SRA[32:63] = $signed(opA[0:31]) >>> SRA_value;
				end
				
				ModeD: begin
					SRA_value = opB[58:63];
					Data_SRA = $signed(opA) >>> SRA_value;	
				end
				
			endcase
		end
	end


//----------------------------------------------------------------------------
//VRTTH operation
	reg [0:63]Data_RTTH;
	
	always @(*) begin
		Data_RTTH = 64'bx;
		if (opcode == VRTTH) begin
			case (wordwidth)
			
				ModeB: begin
					Data_RTTH[0:7]   = {opA[4:7], opA[0:3]};
					Data_RTTH[8:15]  = {opA[12:15], opA[8:11]};
					Data_RTTH[16:23] = {opA[20:23], opA[16:19]};
					Data_RTTH[24:31] = {opA[28:31], opA[24:27]};
					Data_RTTH[32:39] = {opA[36:39], opA[32:35]};
					Data_RTTH[40:47] = {opA[44:47], opA[40:43]};
					Data_RTTH[48:55] = {opA[52:55], opA[48:51]};
					Data_RTTH[56:63] = {opA[60:63], opA[56:59]};
				end
				
				ModeH: begin
					Data_RTTH[0:15]  = {opA[8:15], opA[0:7]};
					Data_RTTH[16:31] = {opA[24:31], opA[16:23]};
					Data_RTTH[32:47] = {opA[40:47], opA[32:39]};
					Data_RTTH[48:63] = {opA[56:63], opA[48:55]};
				end
				
				ModeW: begin
					Data_RTTH[0:31]  = {opA[16:31], opA[0:15]};
					Data_RTTH[32:63] = {opA[48:63], opA[32:47]};
				end
				
				ModeD: Data_RTTH = {opA[32:63], opA[0:31]};
				
			endcase
		end
	end

//----------------------------------------------------------------------------
//VDIV and VMOD operations
	reg [0:63] dividend,divisor;  //generate the input of divider
	
	always @(*) begin
		dividend = opA;
		divisor  = opB; //{64{1'b1}};
		// if ((wordwidth == VDIV) || (wordwidth ==VMOD))
			// divisor = opB;
	end
	
	wire [0:63] Q_b,Q_h,Q_w,Q_d,R_b,R_h,R_w,R_d;  //Quotient and Reminder

	//ModeB
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_0 (
        .a(dividend[0:7]), .b(divisor[0:7]), .quotient(Q_b[0:7]),
        .remainder(R_b[0:7]), .divide_by_0()
    );	
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_1 (
        .a(dividend[8:15]), .b(divisor[8:15]), .quotient(Q_b[8:15]),
        .remainder(R_b[8:15]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_2 (
        .a(dividend[16:23]), .b(divisor[16:23]), .quotient(Q_b[16:23]),
        .remainder(R_b[16:23]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_3 (
        .a(dividend[24:31]), .b(divisor[24:31]), .quotient(Q_b[24:31]),
        .remainder(R_b[24:31]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_4 (
        .a(dividend[32:39]), .b(divisor[32:39]), .quotient(Q_b[32:39]),
        .remainder(R_b[32:39]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_5 (
        .a(dividend[40:47]), .b(divisor[40:47]), .quotient(Q_b[40:47]),
        .remainder(R_b[40:47]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_6 (
        .a(dividend[48:55]), .b(divisor[48:55]), .quotient(Q_b[48:55]),
        .remainder(R_b[48:55]), .divide_by_0()
    );
	
    DW_div #(
        .a_width(8), .b_width(8), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_b_7 (
        .a(dividend[56:63]), .b(divisor[56:63]), .quotient(Q_b[56:63]),
        .remainder(R_b[56:63]), .divide_by_0()
    );
	
	//ModeH
    DW_div #(
        .a_width(16), .b_width(16), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_h_0 (
        .a(dividend[0:15]), .b(divisor[0:15]), .quotient(Q_h[0:15]),
        .remainder(R_h[0:15]), .divide_by_0()
    );	

    DW_div #(
        .a_width(16), .b_width(16), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_h_1 (
        .a(dividend[16:31]), .b(divisor[16:31]), .quotient(Q_h[16:31]),
        .remainder(R_h[16:31]), .divide_by_0()
    );	

    DW_div #(
        .a_width(16), .b_width(16), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_h_2 (
        .a(dividend[32:47]), .b(divisor[32:47]), .quotient(Q_h[32:47]),
        .remainder(R_h[32:47]), .divide_by_0()
    );	

    DW_div #(
        .a_width(16), .b_width(16), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_h_3 (
        .a(dividend[48:63]), .b(divisor[48:63]), .quotient(Q_h[48:63]),
        .remainder(R_h[48:63]), .divide_by_0()
    );		

	//ModeW
    DW_div #(
        .a_width(32), .b_width(32), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_w_0 (
        .a(dividend[0:31]), .b(divisor[0:31]), .quotient(Q_w[0:31]),
        .remainder(R_w[0:31]), .divide_by_0()
    );	
	
    DW_div #(
        .a_width(32), .b_width(32), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_w_1 (
        .a(dividend[32:63]), .b(divisor[32:63]), .quotient(Q_w[32:63]),
        .remainder(R_w[32:63]), .divide_by_0()
    );	
	
	//ModeD
    DW_div #(
        .a_width(64), .b_width(64), .tc_mode(0), .rem_mode(0) 
    )
    DW_div_d_0 (
        .a(dividend), .b(divisor), .quotient(Q_d),
        .remainder(R_d), .divide_by_0()
    );	



//----------------------------------------------------------------------------
//VSQRT operations
	wire [0:63] RootB,RootH,RootW,RootD;
	
	//ModeB
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_0
    (
        .a(opA[0:7]), .root(RootB[4:7])
    );
    assign RootB[0:3] = 0;	
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_1
    (
        .a(opA[8:15]), .root(RootB[12:15])
    );
    assign RootB[8:11] = 0;
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_2
    (
        .a(opA[16:23]), .root(RootB[20:23])
    );
    assign RootB[16:19] = 0;
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_3
    (
        .a(opA[24:31]), .root(RootB[28:31])
    );
    assign RootB[24:27] = 0;
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_4
    (
        .a(opA[32:39]), .root(RootB[36:39])
    );
    assign RootB[32:35] = 0;	
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_5
    (
        .a(opA[40:47]), .root(RootB[44:47])
    );
    assign RootB[40:43] = 0;
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_6
    (
        .a(opA[48:55]), .root(RootB[52:55])
    );
    assign RootB[48:51] = 0;
	
    DW_sqrt #(
        .width(8), .tc_mode(0)
    )
    DW_sqrt_b_7
    (
        .a(opA[56:63]), .root(RootB[60:63])
    );
    assign RootB[56:59] = 0;

	//ModeH
    DW_sqrt #(
        .width(16), .tc_mode(0)
    )
    DW_sqrt_h_0
    (
        .a(opA[0:15]), .root(RootH[8:15])
    );
    assign RootH[0:7] = 0;
	
    DW_sqrt #(
        .width(16), .tc_mode(0)
    )
    DW_sqrt_h_1
    (
        .a(opA[16:31]), .root(RootH[24:31])
    );
    assign RootH[16:23] = 0;
	
    DW_sqrt #(
        .width(16), .tc_mode(0)
    )
    DW_sqrt_h_2
    (
        .a(opA[32:47]), .root(RootH[40:47])
    );
    assign RootH[32:39] = 0;
	
    DW_sqrt #(
        .width(16), .tc_mode(0)
    )
    DW_sqrt_h_3
    (
        .a(opA[48:63]), .root(RootH[56:63])
    );
    assign RootH[48:55] = 0;
	
	//ModeW
    DW_sqrt #(
        .width(32), .tc_mode(0)
    )
    DW_sqrt_w_0
    (
        .a(opA[0:31]), .root(RootW[16:31])
    );
    assign RootW[0:15] = 0;

    DW_sqrt #(
        .width(32), .tc_mode(0)
    )
    DW_sqrt_w_1
    (
        .a(opA[32:63]), .root(RootW[48:63])
    );
    assign RootW[32:47] = 0;

	//ModeD
    DW_sqrt #(
        .width(64), .tc_mode(0)
    )
    DW_sqrt_d_0
    (
        .a(opA[0:63]), .root(RootD[32:63])
    );
    assign RootD[0:31] = 0;



//------------------------------
//Logic funtion and generate the final data output
	reg [0:63] dout;
	always @(*)  begin
		dout = 64'bx;
		
		case (opcode)
		
			VAND: 
				dout = opA & opB;
			VOR:
				dout = opA | opB;
			VXOR:
				dout = opA ^ opB;
			VNOT:
				dout = ~ opA;
			VMOV:
				dout = opA;
			VADD:
				dout = sum;
			VSUB:
				dout = difference;
			VMULEU:
				dout = product_eu;						
			VMULOU:
				dout = product_ou;
			VSLL:
				dout = Data_SLL;
			VSRL:
				dout = Data_SRL;
			VSRA:
				dout = Data_SRA;
			VRTTH:
				dout = Data_RTTH;
			VDIV:
				case (wordwidth)
					ModeB:	dout = Q_b;
					ModeH:	dout = Q_h;
					ModeW:	dout = Q_w;
					ModeD:	dout = Q_d;
				endcase
			VMOD:
				case (wordwidth)
					ModeB:	dout = R_b;
					ModeH:	dout = R_h;
					ModeW:	dout = R_w;
					ModeD:	dout = R_d;	
				endcase
			VSQEU:
				dout = product_eu;
			VSQOU:
				dout = product_ou;
			VSQRT:
				case (wordwidth)
					ModeB:	dout = RootB;
					ModeH:	dout = RootH;
					ModeW:	dout = RootW;
					ModeD:	dout = RootD;
				endcase
		endcase
	end

endmodule
		
		

		
















