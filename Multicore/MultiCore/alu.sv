import pkg::*;


module single_mult_op (
					input wire clk,rst,
					input wire [7:0] A,B,
					input wire start_alu,
					input opcode op_sel,
					output reg [15:0] result_alu,
					output reg end_alu 
					);
					
reg [15:0] mul_temp1,mul_temp2;	
reg [15:0] sf1_temp1,sf1_temp2;
reg [15:0] sf2_temp1,sf2_temp2;
reg [15:0] sf3_temp1,sf3_temp2;
reg [15:0] sf4_temp1,sf4_temp2;

int counter;	

always_ff@(posedge clk)
	begin
		if(rst) begin
			result_alu <= 0;
			end_alu <= 0;
			counter <= 0;
			mul_temp1 <= 0; 
			mul_temp2 <= 0;
			sf1_temp1 <= 0;
			sf1_temp2 <= 0;
			sf2_temp1 <= 0;
			sf2_temp2 <= 0;
			sf3_temp1 <= 0;
			sf3_temp2 <= 0;
			sf4_temp1 <= 0;
			sf4_temp2 <= 0;
		end
		
		else if (start_alu) begin
			//counter <= 0;
			//end_alu <= 0;
			case(op_sel)
				NOP : begin
						result_alu <= 0;
						end_alu <= 1;
					end
				
				ADD : begin
						result_alu <= A + B;
						end_alu <= 1;
					end
				
				AND : begin
						result_alu <= A & B;
						end_alu <= 1;
					end
				
				SUB : begin
						result_alu <= A - B;
						end_alu <= 1;
					end
				
				MUL : begin
							mul_temp1 <= A * B;
							mul_temp2 <= mul_temp1;
							result_alu <= mul_temp2;
							
							if(counter > 1) begin
								counter <= 0;
								end_alu <= 1;
							end
							
							else begin
								counter <= counter + 1;
								//end_alu <= 0;
							end
							
					  end
				
				//LOAD : 
				
				//STORE : 
				
				SHIFT_RIGHT : begin
								result_alu <= {A,B} >> 1;
								end_alu <= 1;
							end
				
				SHIFT_LEFT : begin
								result_alu <= {A,B} << 1;
								end_alu <= 1;
							end
				
				SF1 : begin
							sf1_temp1 <= (A * B) - A;
							sf1_temp2 <= sf1_temp1;
							result_alu <= sf1_temp2;
							
							if(counter > 1) begin
								counter <= 0;
								end_alu <= 1;
							end
							
							else begin
								counter <= counter + 1;
								//end_alu <= 0;
							end
							
					  end
					  
				SF2 : begin
							sf2_temp1 <= (A * 4 * B) - A;
							sf2_temp2 <= sf2_temp1;
							result_alu <= sf2_temp2;
							
							if(counter > 1) begin
								counter <= 0;
								end_alu <= 1;
							end
							
							else begin
								counter <= counter + 1;
								//end_alu <= 0;
							end
							
					  end
					  
				SF3 : begin
							sf3_temp1 <= (A * B) + A;
							sf3_temp2 <= sf3_temp1;
							result_alu <= sf3_temp2;
							
							if(counter > 1) begin
								counter <= 0;
								end_alu <= 1;
							end
							
							else begin
								counter <= counter + 1;
								//end_alu <= 0;
							end
							
					  end
					  
				SF4 : begin
							sf4_temp1 <= (A * 3);
							sf4_temp2 <= sf4_temp1;
							result_alu <= sf4_temp2;
							
							if(counter > 1) begin
								counter <= 0;
								end_alu <= 1;
							end
							
							else begin
								counter <= counter + 1;
								//end_alu <= 0;
							end
							
					  end
					  
				RB1 : begin
							result_alu <= A ^ B;
							end_alu <= 1;
					end
				
				RB2 : begin
							result_alu <= A | B;
							end_alu <= 1;
					end
				
				RB3 : begin
							result_alu <= A ^ ~B;
							end_alu <= 1;
					end
				
				default : result_alu <= 0;
				
			endcase
		end
		
		else 
			end_alu <= 0;
		
		
	end
	


endmodule



module load (
				input clk,rst,
				input [11:0] address_in,
				inout [7:0] data_cache,
				input start_load,
				input gnt,
				input hit,
				output reg end_load,
				output reg valid_load,
				output reg [11:0] address_cache_load,
				output reg [15:0] result_load
			);
			

reg complete;

reg send_addr;
			
typedef enum logic [1:0] {IDLE_LOAD, SEND_ADDR_LOAD, WAIT_LOAD, FINISH_LOAD} load_statetype;

load_statetype state,next_state;

always_ff@(posedge clk)
	begin
		if(rst)
			state <= IDLE_LOAD;
			
		else
			state <= next_state;
	end
	
	
// Output logic 	
always_comb
	begin
		
		case(state)
		
		IDLE_LOAD : begin
						valid_load = 0;
						send_addr = 0;
						complete = 0;
					end
		
		SEND_ADDR_LOAD : begin
							complete = 0;
							send_addr = 1;
							valid_load = 1;
							
						end
		
		WAIT_LOAD : begin
						complete = 0;
						valid_load = 0;
					end
					
		FINISH_LOAD : begin
						complete = 1;
					  end
					  
		endcase

	end
	
	
// Next State logic
always_comb
	begin
	
		next_state = state;
		case(state)
		
		IDLE_LOAD : begin
						if(start_load) next_state = SEND_ADDR_LOAD;
					end
		
		SEND_ADDR_LOAD : begin
							if(hit) next_state = FINISH_LOAD;
							
							else next_state = WAIT_LOAD;
						end
						
		WAIT_LOAD : begin
						if(gnt) next_state = FINISH_LOAD;
					end
					
		FINISH_LOAD : begin
						if(start_load) next_state = IDLE_LOAD;
					end
		
		endcase
	end
	

	
assign end_load = complete;

assign address_cache_load = send_addr ? address_in : 0;

assign result_load = complete ? data_cache : 0;
	
			
endmodule



module store (
				input wire clk,rst,
				input wire [11:0] address_in,
				input wire start_store,
				input wire [7:0] data_in,
				input wire hit,
				input wire gnt,
				output reg [11:0] address_cache_store,
				inout wire [7:0] data_cache,
				output reg [15:0] result_store,
				output reg valid_store,
				output reg end_store
			);

reg complete;

reg send_addr, send_data;

typedef enum logic [1:0] {IDLE_STORE, SEND_ADDR_STORE, WAIT_STORE, FINISH_STORE} store_statetype;

store_statetype state, next_state;

always_ff@(posedge clk)
	begin
		if(rst)
			state <= IDLE_STORE;
		else 
			state <= next_state;
	end
	

// Output logic

always_comb
	begin
		
		case(state)
		
		IDLE_STORE : begin
						valid_store = 0;
						send_addr = 0;
						complete = 0;
					end
		
		SEND_ADDR_STORE : begin
							complete = 0;
							send_addr = 1;
							send_data = 1;
							valid_store = 1;
							
						end
		
		WAIT_STORE : begin
						complete = 0;
						valid_store = 0;
					end
					
		FINISH_STORE : begin
						complete = 1;
					  end
					  
		endcase

	end



// Next State logic 

always_comb
	begin
		
		next_state = state;
		case(state)
		
		IDLE_STORE : begin
						if(start_store) next_state = SEND_ADDR_STORE;
					end
		
		SEND_ADDR_STORE : begin
							if(hit) next_state = FINISH_STORE;
							
							else next_state = WAIT_STORE;
						end
						
		WAIT_STORE : begin
						if(gnt) next_state = FINISH_STORE;
					end
					
		FINISH_STORE : begin
						if(start_store) next_state = IDLE_STORE;
					end
		
		endcase
	end
	
	
assign end_store = complete;

assign result_store = complete;

assign address_cache_store = send_addr ? address_in : 0;

assign data_cache = send_data ? data_in : 0; 

endmodule