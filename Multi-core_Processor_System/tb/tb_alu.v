`include "./include/sim_ver/DW_div.v"
`include "./include/sim_ver/DW_sqrt.v"

`timescale 1ns/1ps

 module tb_alu;
    reg [0:63] opA, opB;
    reg [0:5] opcode;
    reg [0:1] wordwidth;
    wire [0:63] dout;

    localparam  VAND = 6'b000001,
                VOR = 6'b000010,
                VXOR = 6'b000011,
                VNOT = 6'b000100,
                VMOV = 6'b000101, 
                VADD = 6'b000110,
                VSUB = 6'b000111,
                VMULEU = 6'b001000,
                VMULOU = 6'b001001,
                VSLL = 6'b001010,
                VSRL = 6'b001011,
                VSRA = 6'b001100,
                VRTTH = 6'b001101,
                VDIV = 6'b001110,
                VMOD = 6'b001111, 
                VSQEU = 6'b010000,
                VSQOU = 6'b010001,
                VSQRT = 6'b010010;


    localparam  ModeB = 2'b00, // byte mode
                ModeH = 2'b01, // half word mode
                ModeW = 2'b10, // word mode
                ModeD = 2'b11; // doutuble word mode

    // Instantiation of DUT:
    alu alu_dut
    (
        .opA(opA),
        .opB(opB),
        .opcode(opcode),
        .wordwidth(wordwidth),
        .dout(dout)
    );

    integer out_file;
    initial 
    begin
        out_file = $fopen("alu_result.out", "w");
//-----------------------------------------------------------------------------------------------------------------------
// VADD:
        #4
        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'b1;
        opcode = VADD;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "ADD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'b1;
        opcode = VADD;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "ADD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);     

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'b1;
        opcode = VADD;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "ADD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'b1;
        opcode = VADD;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "ADD: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// SUB:
        opA = 64'h0;
        opB = 64'b1;
        opcode = VSUB;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SUB: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);

        opA = 64'h0;
        opB = 64'b1;
        opcode = VSUB;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SUB: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);     

        opA = 64'h0;
        opB = 64'b1;
        opcode = VSUB;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SUB: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);

        opA = 64'h0;
        opB = 64'b1;
        opcode = VSUB;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "SUB: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// AND:
        opA = 64'hf0_f0_f0_f0_f0_f0_f0_f0;
        opB = 64'hff_ff_ff_ff_f0_f0_f0_f0;
        opcode = VAND;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "AND: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);
//-----------------------------------------------------------------------------------------------------------------------
// OR:
        opA = 64'hf0_f0_f0_f0_f0_f0_f0_f0;
        opB = 64'b0;
        opcode = VOR;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "OR: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);     
//-----------------------------------------------------------------------------------------------------------------------
// XOR:        
        opA = 64'hf0_f0_f0_f0_f0_f0_f0_f0;
        opB = 64'b0;
        opcode = VXOR;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "XOR: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);
//-----------------------------------------------------------------------------------------------------------------------
// NOT:
        opA = 64'hf0_f0_f0_f0_f0_f0_f0_f0;
        opB = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opcode = VNOT;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "NOT: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 
//-----------------------------------------------------------------------------------------------------------------------
// MOV:
        opA = 64'hf0_f0_f0_f0_f0_f0_f0_f0;
        opB = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opcode = VMOV;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "MOV: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// MULEU:
        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULEU;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "MULEU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULEU;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "MULEU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULEU;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "MULEU: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// MULOU:
        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULOU;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "MULOU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULOU;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "MULOU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h01_02_03_04_05_06_07_08;
        opcode = VMULOU;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "MULOU: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);

//-----------------------------------------------------------------------------------------------------------------------
// SQEU:
        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQEU;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SQEU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQEU;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SQEU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQEU;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SQEU: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);

//-----------------------------------------------------------------------------------------------------------------------
// SQOU:
        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQOU;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SQOU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQOU;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SQOU: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h01_02_03_04_05_06_07_08;
        opB = 64'h0;
        opcode = VSQOU;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SQOU: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);

//-----------------------------------------------------------------------------------------------------------------------
// DIV:
        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VDIV;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "DIV: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VDIV;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "DIV: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VDIV;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "DIV: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VDIV;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "DIV: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// MOD:
        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VMOD;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "MOD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VMOD;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "MOD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VMOD;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "MOD: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_f0_f0_0f_0f_00_00;
        opB = 64'h02_02_02_02_02_02_02_02;
        opcode = VMOD;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "MOD: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// SQRT:
        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'hx;
        opcode = VSQRT;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SQRT: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'hx;
        opcode = VSQRT;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SQRT: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);  

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'hx;
        opcode = VSQRT;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SQRT: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'hx;
        opcode = VSQRT;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "SQRT: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 


//-----------------------------------------------------------------------------------------------------------------------
// SLL:
        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_01_02_03_04_05_06_07; 
        opcode = VSLL;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SLL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_02_00_06_00_0a_00_0e; 	
        opcode = VSLL;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SLL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout);   

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_08_00_00_00_11; 	
        opcode = VSLL;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SLL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_00_00_00_00_30; 
        opcode = VSLL;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "SLL: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);  

//-----------------------------------------------------------------------------------------------------------------------
// SRL:
        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_01_02_03_04_05_06_07; 
        opcode = VSRL;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SRL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_02_00_06_00_0a_00_0e; 	
        opcode = VSRL;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SRL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_08_00_00_00_11; 	
        opcode = VSRL;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SRL: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout,); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_00_00_00_00_30; 
        opcode = VSRL;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "SRL: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout); 

//-----------------------------------------------------------------------------------------------------------------------
// SRA:
        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_01_02_03_04_05_06_07; 
        opcode = VSRA;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "SRA: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_02_00_06_00_0a_00_0e; 
        opcode = VSRA;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "SRA: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_08_00_00_00_11; 	
        opcode = VSRA;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "SRA: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'hff_ff_ff_ff_ff_ff_ff_ff;
        opB = 64'h00_00_00_00_00_00_00_30; 
        opcode = VSRA;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "SRA: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);  

//-----------------------------------------------------------------------------------------------------------------------
// RTTH:
        opA = 64'h00_01_02_03_04_05_06_07;
        opB = 64'bx;
        opcode = VRTTH;
        wordwidth = ModeB;
        #1 
        $fdisplay(out_file, "RTTH: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h00_01_02_03_04_05_06_07;
        opB = 64'bx;
        opcode = VRTTH;
        wordwidth = ModeH;
        #1 
        $fdisplay(out_file, "RTTH: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h00_01_02_03_04_05_06_07;
        opB = 64'bx;
        opcode = VRTTH;
        wordwidth = ModeW;
        #1 
        $fdisplay(out_file, "RTTH: opA = %h, opB = %h, ww = %b, dout = %h", opA, opB, wordwidth, dout); 

        opA = 64'h00_01_02_03_04_05_06_07;
        opB = 64'bx;
        opcode = VRTTH;
        wordwidth = ModeD;
        #1 
        $fdisplay(out_file, "RTTH: opA = %h, opB = %h, ww = %b, dout = %h\n", opA, opB, wordwidth, dout);
//-----------------------------------------------------------------------------------------------------------------------

        #10
        $fclose(out_file);
        $finish;

    end
 endmodule