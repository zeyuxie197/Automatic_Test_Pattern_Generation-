module rotating_prioritizer (clk, reset, polarity, rq0, rq1, gt0, gt1);

	input clk, reset, polarity, rq0, rq1;
	output reg gt0,gt1;
	
	reg gt_last_bf0,gt_last_bf1;  //0 means rq0 was granted last time. 1 means rq1 was granted. 
	
	//Input Barrel shifter
	reg R0,R1;  // output of the Input Barrel shifter
	always @(*)
	begin
		if (polarity) 
		if (~ gt_last_bf1)	begin  //if rq0 was granted last time, do the switch 
			R0 = rq1;
			R1 = rq0;  
			end
		else  begin
			R0 = rq0;
			R1 = rq1;
			end
			
		else 
		if (~ gt_last_bf0)	begin
			R0 = rq1;
			R1 = rq0;  
			end
		else  begin
			R0 = rq0;
			R1 = rq1;
			end
		
	end
	
	//Fixed priority resolver
	reg G0,G1; // output of the Fixed priority resolver
	always  @(*)
	begin
		if (R0)  begin
			G0 = 1;
			G1 = 0;  
			end
		else if (R1)  begin
			G0 = 0;
			G1 = 1;
			end
		else begin
			G0 = 0;
			G1 = 0;
			end
	end
	
	//Output Barrel shifter
	always @(*)
	begin
		if(polarity)
		if (~ gt_last_bf1)	begin
			gt0 = G1;
			gt1 = G0;  
			end
		else  begin
			gt0 = G0;
			gt1 = G1;
			end
			
		else
		if (~ gt_last_bf0)	begin
			gt0 = G1;
			gt1 = G0;  
			end
		else  begin
			gt0 = G0;
			gt1 = G1;
			end
			
	end	
	
	//register that stores the last grant value
	always @( posedge clk)
	begin
		if (reset) begin
			gt_last_bf0 <= 1; 
			gt_last_bf1 <= 1;	end
		else  begin
			if (polarity)
			if ( ~rq0 || ~rq1)
				gt_last_bf1 <= gt_last_bf1;
			else  begin
				if (gt0) gt_last_bf1 <= 0;
				if (gt1) gt_last_bf1 <= 1;
				end
			
			else
			if ( ~rq0 || ~rq1)
				gt_last_bf0 <= gt_last_bf0;
			else  begin
				if (gt0) gt_last_bf0 <= 0;
				if (gt1) gt_last_bf0 <= 1;
				end
				
		end
	end

endmodule
	
	
	
	
	
	