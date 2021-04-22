`include "buffer_router.v"
`include "rotating_prioritizer.v"

module gold_router(clk,reset,polarity,cwsi,cwri,cwdi,cwso,cwro,cwdo,
                    ccwsi,ccwri,ccwdi,ccwso,ccwro,ccwdo,pesi,peri,pedi,peso,pero,pedo);

	input clk,reset;
	input cwsi,ccwsi,pesi,cwro,ccwro,pero;
	input [63:0] cwdi,ccwdi,pedi;      //data in
	input polarity;
	output reg cwri,ccwri,peri,cwso,ccwso,peso;
	output reg [63:0] cwdo,ccwdo,pedo;     //data out
	
	reg [63:0] cw_in_bf0,cw_in_bf1,ccw_in_bf0,ccw_in_bf1,pe_in_bf0,pe_in_bf1;
	reg [63:0] cw_out_bf0,cw_out_bf1,ccw_out_bf0,ccw_out_bf1,pe_out_bf0,pe_out_bf1;
	                                  //bf0 are even channels ,bf1 are odd channels
										



//input buffer and control logic
	wire  empty_cw_in_bf0,empty_cw_in_bf1,empty_ccw_in_bf0,empty_ccw_in_bf1,empty_pe_in_bf0,empty_pe_in_bf1;   //empty signals	
	wire  full_cw_in_bf0,full_cw_in_bf1,full_ccw_in_bf0,full_ccw_in_bf1,full_pe_in_bf0,full_pe_in_bf1;    //full signals	
	reg  we_cw_in_bf0,we_cw_in_bf1,we_ccw_in_bf0,we_ccw_in_bf1,we_pe_in_bf0,we_pe_in_bf1;        //write enable signals
	reg  re_cw_in_bf0,re_cw_in_bf1,re_ccw_in_bf0,re_ccw_in_bf1,re_pe_in_bf0,re_pe_in_bf1;        //read enable signals
	wire [63:0] do_cw_in_bf0, do_cw_in_bf1,do_ccw_in_bf0, do_ccw_in_bf1,do_pe_in_bf0, do_pe_in_bf1;      //data out of input buffers

	//generate the we signals
	always @(*)
	begin
		if (polarity)	begin	//in odd clk, latch the data into even channels
			we_cw_in_bf1 = 0;
			we_ccw_in_bf1 = 0;
			we_pe_in_bf1 = 0;			
			if (cwsi && cwri)    we_cw_in_bf0 = 1;
			else         		 we_cw_in_bf0 = 0;	
			if (ccwsi && ccwri)    we_ccw_in_bf0 = 1;
			else         		 we_ccw_in_bf0 = 0;	
			if (pesi && peri)    we_pe_in_bf0 = 1;
			else         		 we_pe_in_bf0 = 0;	end

		else  begin           //in even clk, latch the data into odd channels
			we_cw_in_bf0 = 0;
			we_ccw_in_bf0 = 0;
			we_pe_in_bf0 = 0;			
			if (cwsi && cwri)    we_cw_in_bf1 = 1;
			else         		 we_cw_in_bf1 = 0;	
			if (ccwsi && ccwri)  we_ccw_in_bf1 = 1;
			else         		 we_ccw_in_bf1 = 0;		
			if (pesi && peri)    we_pe_in_bf1 = 1;
			else         		 we_pe_in_bf1 = 0;	end					
	end

    //generate the ready_input signals
	always @(*)
	begin		
		if (polarity)	begin     //in odd clk, if bf0 is empty, send ready
			if (empty_cw_in_bf0)	cwri = 1;
			else					cwri = 0;	
			if (empty_ccw_in_bf0)	ccwri = 1;
			else					ccwri = 0;	
			if (empty_pe_in_bf0)	peri = 1;
			else					peri = 0;	end

		else  begin
			if (empty_cw_in_bf1)	cwri = 1;
			else					cwri = 0;	
			if (empty_ccw_in_bf1)	ccwri = 1;
			else					ccwri = 0;	
			if (empty_pe_in_bf1)	peri = 1;
			else					peri = 0;	end	
	end
	
	//input buffers
	buffer_router cw_i_bf0 (
	.clk(clk), .reset(reset), .Re(re_cw_in_bf0), .We(we_cw_in_bf0),
	.data_in(cwdi), .data_out(do_cw_in_bf0), 
	.full(full_cw_in_bf0), .empty(empty_cw_in_bf0) );
	
	buffer_router cw_i_bf1 (
	.clk(clk), .reset(reset), .Re(re_cw_in_bf1), .We(we_cw_in_bf1),
	.data_in(cwdi), .data_out(do_cw_in_bf1), 
	.full(full_cw_in_bf1), .empty(empty_cw_in_bf1) );	

	buffer_router ccw_i_bf0 (
	.clk(clk), .reset(reset), .Re(re_ccw_in_bf0), .We(we_ccw_in_bf0),
	.data_in(ccwdi), .data_out(do_ccw_in_bf0), 
	.full(full_ccw_in_bf0), .empty(empty_ccw_in_bf0) );

	buffer_router ccw_i_bf1 (
	.clk(clk), .reset(reset), .Re(re_ccw_in_bf1), .We(we_ccw_in_bf1),
	.data_in(ccwdi), .data_out(do_ccw_in_bf1), 
	.full(full_ccw_in_bf1), .empty(empty_ccw_in_bf1) );

	buffer_router pe_i_bf0 (
	.clk(clk), .reset(reset), .Re(re_pe_in_bf0), .We(we_pe_in_bf0),
	.data_in(pedi), .data_out(do_pe_in_bf0), 
	.full(full_pe_in_bf0), .empty(empty_pe_in_bf0) );
	
	buffer_router pe_i_bf1 (
	.clk(clk), .reset(reset), .Re(re_pe_in_bf1), .We(we_pe_in_bf1),
	.data_in(pedi), .data_out(do_pe_in_bf1), 
	.full(full_pe_in_bf1), .empty(empty_pe_in_bf1) );

	


//output buffer and control logic
	wire empty_cw_out_bf0,empty_cw_out_bf1,empty_ccw_out_bf0,empty_ccw_out_bf1,empty_pe_out_bf0,empty_pe_out_bf1;   //empty signals	
	wire full_cw_out_bf0,full_cw_out_bf1,full_ccw_out_bf0,full_ccw_out_bf1,full_pe_out_bf0,full_pe_out_bf1;    //full signals	
	reg  we_cw_out_bf0,we_cw_out_bf1,we_ccw_out_bf0,we_ccw_out_bf1,we_pe_out_bf0,we_pe_out_bf1;        //write enable signals
	reg  re_cw_out_bf0,re_cw_out_bf1,re_ccw_out_bf0,re_ccw_out_bf1,re_pe_out_bf0,re_pe_out_bf1;        //read enable signals
	reg [63:0] di_cw_out_bf0, di_cw_out_bf1,di_ccw_out_bf0, di_ccw_out_bf1,di_pe_out_bf0, di_pe_out_bf1;      //data in of output buffers
	wire [63:0] do_cw_out_bf0, do_cw_out_bf1,do_ccw_out_bf0, do_ccw_out_bf1,do_pe_out_bf0, do_pe_out_bf1;      //data out of output buffers


	//output buffers
	buffer_router cw_o_bf0 (
	.clk(clk), .reset(reset), .Re(re_cw_out_bf0), .We(we_cw_out_bf0),
	.data_in(di_cw_out_bf0), .data_out(do_cw_out_bf0), 
	.full(full_cw_out_bf0), .empty(empty_cw_out_bf0) );
	
	buffer_router cw_o_bf1 (
	.clk(clk), .reset(reset), .Re(re_cw_out_bf1), .We(we_cw_out_bf1),
	.data_in(di_cw_out_bf1), .data_out(do_cw_out_bf1), 
	.full(full_cw_out_bf1), .empty(empty_cw_out_bf1) );	

	buffer_router ccw_o_bf0 (
	.clk(clk), .reset(reset), .Re(re_ccw_out_bf0), .We(we_ccw_out_bf0),
	.data_in(di_ccw_out_bf0), .data_out(do_ccw_out_bf0), 
	.full(full_ccw_out_bf0), .empty(empty_ccw_out_bf0) );

	buffer_router ccw_o_bf1 (
	.clk(clk), .reset(reset), .Re(re_ccw_out_bf1), .We(we_ccw_out_bf1),
	.data_in(di_ccw_out_bf1), .data_out(do_ccw_out_bf1), 
	.full(full_ccw_out_bf1), .empty(empty_ccw_out_bf1) );

	buffer_router pe_o_bf0 (
	.clk(clk), .reset(reset), .Re(re_pe_out_bf0), .We(we_pe_out_bf0),
	.data_in(di_pe_out_bf0), .data_out(do_pe_out_bf0), 
	.full(full_pe_out_bf0), .empty(empty_pe_out_bf0) );
	
	buffer_router pe_o_bf1 (
	.clk(clk), .reset(reset), .Re(re_pe_out_bf1), .We(we_pe_out_bf1),
	.data_in(di_pe_out_bf1), .data_out(do_pe_out_bf1), 
	.full(full_pe_out_bf1), .empty(empty_pe_out_bf1) );



	//generate the request signals
	reg rq_cw_cw,rq_cw_pe,rq_ccw_ccw,rq_ccw_pe,rq_pe_cw,rq_pe_ccw;  //rq_cw_pe means the request of sending data from cw_in to pe_out
	
	always @(*)
	begin
		rq_cw_cw = 0;
		rq_cw_pe = 0;
		rq_ccw_ccw = 0;
		rq_ccw_pe = 0;
		rq_pe_cw = 0;
		rq_pe_ccw = 0;
		
		if (polarity)
		  begin
			if (full_cw_in_bf1 && empty_cw_out_bf1 && do_cw_in_bf1[48])
				rq_cw_cw = 1;
			if (full_cw_in_bf1 && empty_pe_out_bf1 && ~ do_cw_in_bf1[48])
				rq_cw_pe = 1;
			if (full_ccw_in_bf1 && empty_ccw_out_bf1 && do_ccw_in_bf1[48])
				rq_ccw_ccw = 1;
			if (full_ccw_in_bf1 && empty_pe_out_bf1 && ~ do_ccw_in_bf1[48])
				rq_ccw_pe = 1;
			if (full_pe_in_bf1 && empty_cw_out_bf1 && ~ do_pe_in_bf1[62])
				rq_pe_cw = 1;
			if (full_pe_in_bf1 && empty_ccw_out_bf1 && do_pe_in_bf1[62])
				rq_pe_ccw = 1;
		  end
		else
		  begin
			if (full_cw_in_bf0 && empty_cw_out_bf0 && do_cw_in_bf0[48])
				rq_cw_cw = 1;
			if (full_cw_in_bf0 && empty_pe_out_bf0 && ~ do_cw_in_bf0[48])
				rq_cw_pe = 1;
			if (full_ccw_in_bf0 && empty_ccw_out_bf0 && do_ccw_in_bf0[48])
				rq_ccw_ccw = 1;
			if (full_ccw_in_bf0 && empty_pe_out_bf0 && ~ do_ccw_in_bf0[48])
				rq_ccw_pe = 1;
			if (full_pe_in_bf0 && empty_cw_out_bf0 && ~ do_pe_in_bf0[62])
				rq_pe_cw = 1;
			if (full_pe_in_bf0 && empty_ccw_out_bf0 && do_pe_in_bf0[62])
				rq_pe_ccw = 1;
		  end	
	end
			


	//rotating prioritizer design, generate the grant signals
	wire gnt_cw_cw,gnt_cw_pe,gnt_ccw_ccw,gnt_ccw_pe,gnt_pe_cw,gnt_pe_ccw;  //gnt_cw_pe means the request from cw_in to pe_out is granted.
	
	
	rotating_prioritizer rp_cw (
	.clk(clk), .reset(reset), .polarity(polarity), .rq0(rq_cw_cw), .rq1(rq_pe_cw),
	.gt0(gnt_cw_cw), .gt1(gnt_pe_cw) );
	
	rotating_prioritizer rp_ccw (
	.clk(clk), .reset(reset), .polarity(polarity), .rq0(rq_ccw_ccw), .rq1(rq_pe_ccw),
	.gt0(gnt_ccw_ccw), .gt1(gnt_pe_ccw) );	
	
	rotating_prioritizer rp_pe (
	.clk(clk), .reset(reset), .polarity(polarity), .rq0(rq_cw_pe), .rq1(rq_ccw_pe),
	.gt0(gnt_cw_pe), .gt1(gnt_ccw_pe) );	
	
	//generate the re signal of out_buffer
	always @(*)
	begin
		if ( ~ polarity)  begin
			re_cw_out_bf0 = 0;
			re_ccw_out_bf0 = 0;
			re_pe_out_bf0 = 0;
			if (cwso && cwro)  re_cw_out_bf1 = 1;
				else		   re_cw_out_bf1 = 0;
			if (ccwso && ccwro)  re_ccw_out_bf1 = 1;
				else		   re_ccw_out_bf1 = 0;
			if (peso && pero)  re_pe_out_bf1 = 1;
				else		   re_pe_out_bf1 = 0;
			end
		else begin
			re_cw_out_bf1 = 0;
			re_ccw_out_bf1 = 0;
			re_pe_out_bf1 = 0;
			if (cwso && cwro)  re_cw_out_bf0 = 1;
				else		   re_cw_out_bf0 = 0;
			if (ccwso && ccwro)  re_ccw_out_bf0 = 1;
				else		   re_ccw_out_bf0 = 0;
			if (peso && pero)  re_pe_out_bf0 = 1;
				else		   re_pe_out_bf0 = 0;
			end	
	end
	
	//generate the we_out, re_in, di_out;
	always @(*)
	begin
		re_cw_in_bf0 = 0;
		re_cw_in_bf1 = 0;
		re_ccw_in_bf0 = 0;
		re_ccw_in_bf1 = 0;
		re_pe_in_bf0 = 0;
		re_pe_in_bf1 = 0;
		
		we_cw_out_bf0 = 0;
		we_cw_out_bf1 = 0;
		we_ccw_out_bf0 = 0;
		we_ccw_out_bf1 = 0;
		we_pe_out_bf0 = 0;
		we_pe_out_bf1 = 0;
		
		di_cw_out_bf0 = 0;
		di_cw_out_bf1 = 0;
		di_ccw_out_bf0 = 0;
		di_ccw_out_bf1 = 0;
		di_pe_out_bf0 = 0;
		di_pe_out_bf1 = 0;		
		
		if ( ~ polarity)  begin
			if (gnt_cw_cw) begin
				re_cw_in_bf0 = 1;
				we_cw_out_bf0 = 1;
				di_cw_out_bf0 = {do_cw_in_bf0[63:56],1'b0,do_cw_in_bf0[55:49],do_cw_in_bf0[47:0]};
			end
			
			if (gnt_cw_pe) begin
				re_cw_in_bf0 = 1;
				we_pe_out_bf0 = 1;
				di_pe_out_bf0 = {do_cw_in_bf0[63:56],1'b0,do_cw_in_bf0[55:49],do_cw_in_bf0[47:0]};
			end
			
			if (gnt_ccw_ccw) begin
				re_ccw_in_bf0 = 1;
				we_ccw_out_bf0 = 1;
				di_ccw_out_bf0 = {do_ccw_in_bf0[63:56],1'b0,do_ccw_in_bf0[55:49],do_ccw_in_bf0[47:0]};
			end
			
			if (gnt_ccw_pe) begin
				re_ccw_in_bf0 = 1;
				we_pe_out_bf0 = 1;
				di_pe_out_bf0 = {do_ccw_in_bf0[63:56],1'b0,do_ccw_in_bf0[55:49],do_ccw_in_bf0[47:0]};
			end
			
			if (gnt_pe_cw) begin
				re_pe_in_bf0 = 1;
				we_cw_out_bf0 = 1;
				di_cw_out_bf0 = {do_pe_in_bf0[63:56],1'b0,do_pe_in_bf0[55:49],do_pe_in_bf0[47:0]};
			end			
			
			if (gnt_pe_ccw) begin
				re_pe_in_bf0 = 1;
				we_ccw_out_bf0 = 1;
				di_ccw_out_bf0 = {do_pe_in_bf0[63:56],1'b0,do_pe_in_bf0[55:49],do_pe_in_bf0[47:0]};
			end
		end
		
		else begin
			if (gnt_cw_cw) begin
				re_cw_in_bf1 = 1;
				we_cw_out_bf1 = 1;
				di_cw_out_bf1 = {do_cw_in_bf1[63:56],1'b0,do_cw_in_bf1[55:49],do_cw_in_bf1[47:0]};
			end
			
			if (gnt_cw_pe) begin
				re_cw_in_bf1 = 1;
				we_pe_out_bf1 = 1;
				di_pe_out_bf1 = {do_cw_in_bf1[63:56],1'b0,do_cw_in_bf1[55:49],do_cw_in_bf1[47:0]};
			end
			
			if (gnt_ccw_ccw) begin
				re_ccw_in_bf1 = 1;
				we_ccw_out_bf1 = 1;
				di_ccw_out_bf1 = {do_ccw_in_bf1[63:56],1'b0,do_ccw_in_bf1[55:49],do_ccw_in_bf1[47:0]};
			end
			
			if (gnt_ccw_pe) begin
				re_ccw_in_bf1 = 1;
				we_pe_out_bf1 = 1;
				di_pe_out_bf1 = {do_ccw_in_bf1[63:56],1'b0,do_ccw_in_bf1[55:49],do_ccw_in_bf1[47:0]};
			end
			
			if (gnt_pe_cw) begin
				re_pe_in_bf1 = 1;
				we_cw_out_bf1 = 1;
				di_cw_out_bf1 = {do_pe_in_bf1[63:56],1'b0,do_pe_in_bf1[55:49],do_pe_in_bf1[47:0]};
			end			
			
			if (gnt_pe_ccw) begin
				re_pe_in_bf1 = 1;
				we_ccw_out_bf1 = 1;
				di_ccw_out_bf1 = {do_pe_in_bf1[63:56],1'b0,do_pe_in_bf1[55:49],do_pe_in_bf1[47:0]};
			end
		end	
			
	end
	
	//generate send_out and data_out signals
	always @(*)
	begin
		if(polarity)  begin
			cwdo = do_cw_out_bf0;
			ccwdo = do_ccw_out_bf0;
			pedo = do_pe_out_bf0;
			if (full_cw_out_bf0 && cwro)	cwso = 1;
			else							cwso = 0;
				
			if (full_ccw_out_bf0 && ccwro)	ccwso = 1;
			else							ccwso = 0;
			
			if (full_pe_out_bf0 && pero)	peso = 1;
			else 							peso = 0;  end
				
		else  begin
			cwdo = do_cw_out_bf1;
			ccwdo = do_ccw_out_bf1;
			pedo = do_pe_out_bf1;
			if (full_cw_out_bf1 && cwro)	cwso = 1;
			else							cwso = 0;
				
			if (full_ccw_out_bf1 && ccwro)	ccwso = 1;
			else							ccwso = 0;
			
			if (full_pe_out_bf1 && pero)	peso = 1;
			else 							peso = 0;  end
				
	end
	

endmodule
	
















