package pkg;
	typedef enum logic [3:0] {
							NOP = 4'b0000,
							ADD = 4'b0001,
							AND = 4'b0010,
							SUB = 4'b0011,
							MUL = 4'b0100,
							LOAD = 4'b0101,
							STORE = 4'b0110,
							SHIFT_RIGHT = 4'b0111,
							SHIFT_LEFT = 4'b1000,
							SF1 = 4'b1001,
							SF2 = 4'b1010,
							SF3 = 4'b1011,
							SF4 = 4'b1100,
							RB1 = 4'b1101,
							RB2 = 4'b1110,
							RB3 = 4'b1111
						} opcode;
						
endpackage