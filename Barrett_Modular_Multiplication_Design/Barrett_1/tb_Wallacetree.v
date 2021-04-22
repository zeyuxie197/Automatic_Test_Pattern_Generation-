module tb_Wallacetree_4;
    reg [3:0] A;
    reg [3:0] B;

    wire [7:0] M_OUT;
    wire [6:0] P0;
    integer i,j,error;

    Wallace_tree_4 DUT (A,B,M_OUT);
    

    initial begin
        $monitor ("A B M_OUT = %d %d %d", A, B, M_OUT);
        error = 0;
        for(i=0;i <=15;i = i+1)
            for(j=0;j <=15;j = j+1) 
            begin
                A <= i; 
                B <= j;
                #1;
                if(M_OUT != A*B) //if the result isnt correct increment "error".
                    error = error + 1;  
            end     
    end
      
endmodule
