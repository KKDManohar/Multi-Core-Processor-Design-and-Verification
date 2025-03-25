module cache(
				input clk,rst,
				input rw,valid,
				input [11:0] address_cache,
				input gnt_arb,
				inout [7:0] data_cache,
				output reg hit,cpu_gnt,
				output reg req_arb
			);
			
	reg [4:0] cache_tag [0:127];
			
	reg [7:0] cache_mem [0:127];
	
	reg [11:0] temp_addr;
	
	reg addr_storing, send_data, receive_data;
	
	reg hit_ack, cpu_gnt_ack, req_arb_ack;
	
	typedef enum logic [2:0] {IDLE_CACHE, CHECK_CACHE, CHECK_SEND, CHECK_RECEIVE, WAIT_CACHE, SENDING, RECEIVING, FINISH_CACHE} cache_statetype;
	
	cache_statetype state, next_state;
	
	always_ff@(posedge clk) begin
		if(rst)
			state <= IDLE_CACHE;
		else
			state <= next_state;
	end
	
	// Output logic
	
	always_comb begin
		case(state) 
		
		IDLE_CACHE : begin
						hit_ack = 0;
						cpu_gnt_ack = 0;
						req_arb_ack = 0;
						addr_storing = 0;
					end
					
		CHECK_CACHE : addr_storing = 1;
		
		CHECK_SEND : begin
						for(int i=0;i<128;i++) begin
							if(i == temp_addr[6:0]) begin
								if(cache_tag[i] == temp_addr[11:7]) begin
									hit_ack = 1;
									//send_data = 1;
								end
							
								else begin
									hit_ack = 0;
									//send_data = 0;
								end
							
							end
							
							else begin
								hit_ack = 0;
								//send_data = 0;
							end
						end
					end
				  
		CHECK_RECEIVE : begin
							for(int i=0;i<128;i++) begin
								if(i == temp_addr[6:0]) begin
									if(cache_tag[i] == temp_addr[11:7]) begin
										hit_ack = 1;
										//receive_data = 1;
									end
							
									else begin
										hit_ack = 0;
										//receive_data = 0;
									end
							
								end
								
								else begin
									hit_ack = 0;
									//receive_data = 0;
								end
							end
						end
				  
		WAIT_CACHE : req_arb_ack = 1;
		
		SENDING : send_data = 1;
		
		RECEIVING : receive_data = 1;
		
		FINISH_CACHE : cpu_gnt_ack = 1;
		
		endcase
		
	end
	
	
	
	// Next State logic 
	
	always_comb begin
		next_state = state;
		case(state)
		
		IDLE_CACHE : begin
						if(valid) next_state = CHECK_CACHE;
					end
					
		CHECK_CACHE : begin
						if(rw) next_state = CHECK_SEND;
						
						else if(!rw) next_state = CHECK_RECEIVE;
					end
					
		CHECK_SEND : begin
						for(int i=0;i<128;i++) begin
							if(i == temp_addr[6:0]) begin
								if(cache_tag[i] == temp_addr[11:7]) begin
									next_state = SENDING;
								end
							
								else begin
									next_state = WAIT_CACHE;
								end
							end
							
							else begin
								next_state = WAIT_CACHE;
								end
							end
					end
						
		CHECK_RECEIVE : begin
							for(int i=0;i<128;i++) begin
								if(i == temp_addr[6:0]) begin
									if(cache_tag[i] == temp_addr[11:7]) begin
										next_state = RECEIVING;
									end
								
									else begin
										next_state = WAIT_CACHE;
									end
								end
								
								else begin
									next_state = WAIT_CACHE;
									end
								end
						end
		
		WAIT_CACHE : begin
						if(rw) next_state = SENDING;
						
						else if(!rw) next_state = RECEIVING;
					end
					
		SENDING : next_state = FINISH_CACHE;
		
		RECEIVING : next_state = FINISH_CACHE;
		
		FINISH_CACHE : next_state = IDLE_CACHE;
		
		endcase
	end
	
	assign temp_addr = addr_storing ? address_cache : 'z;
	
	assign hit = hit_ack ? 1 : 0;
	
	assign cpu_gnt = cpu_gnt_ack;
	
	assign req_arb = req_arb_ack ? 1 : 0;
	
	assign data_cache = send_data ? cache_mem[temp_addr[6:0]] : 'z;
	
	always_ff@(posedge clk) begin
		if(receive_data)
			cache_mem[temp_addr[6:0]] <= data_cache;
	end
		
endmodule