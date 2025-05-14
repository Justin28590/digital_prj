module mult_digit#(
	//Parameterized values
	parameter Q = 15,
	parameter N = 32
	)
	(
	input 	[N-1:0]  i_multiplicand,
	input 	[N-1:0]	i_multiplier,
	input 	i_start,
	input 	i_clk,
	output reg 	[N-1:0] o_result_out,
	output 	reg reg_done
	);

	reg [2*N-2:0]	reg_working_result;		//	a place to accumulate our result
	reg [2*N-2:0]	reg_multiplier_temp;		//	a working copy of the multiplier
	reg [N-1:0]		reg_multiplicand_temp;	//	a working copy of the umultiplicand
	reg [$clog2(N):0] 			reg_count; 		
										 
	reg	reg_sign = 1'b0;		//	The result's sign bit

	initial reg_done <= 1'b0;
 
	always @( posedge i_clk ) begin
		if(i_start) begin										//	This is our startup condition
			reg_done <= 1'b0;														//	We're not done			
			reg_count <= 0;														//	Reset the count
			reg_working_result <= 0;											//	Clear out the result register
			reg_multiplier_temp <= 0;											//	Clear out the multiplier register 
			reg_multiplicand_temp <= 0;										//	Clear out the multiplicand register 

			reg_multiplicand_temp <= i_multiplicand[N-2:0];				//	Load the multiplicand in its working register and lose the sign bit
			reg_multiplier_temp <= i_multiplier[N-2:0];					//	Load the multiplier into its working register and lose the sign bit

			reg_sign <= i_multiplicand[N-1] ^ i_multiplier[N-1];		//	Set the sign bit
			end 

		else if (!reg_done) begin
			if (reg_multiplicand_temp[reg_count] == 1'b1)								//	if the appropriate multiplicand bit is 1
				reg_working_result <= reg_working_result + reg_multiplier_temp;	//		then add the temp multiplier
	
			reg_multiplier_temp <= reg_multiplier_temp << 1;						//	Do a left-shift on the multiplier
			reg_count <= reg_count + 1;													//	Increment the count

			//stop condition
				if(reg_count == N) begin
					reg_done <= 1'b1;										//	If we're done, it's time to tell the calling process
					o_result_out <= (reg_sign == 1'b1) ? {1'b1, -reg_working_result[N-2+Q:Q]}: {1'b0, reg_working_result[N-2+Q:Q]};
				end
			end
		end
endmodule
