module arbiter (
				input wire clk, rst,
				input wire req_arb[3],
				output reg gnt_arb[3]
				);

    reg mask[3];
    reg masked_req_arb[3];
    reg next_gnt_arb[3];

    always_ff @(posedge clk) begin
        if (rst)
            mask <= '{1, 0, 0};  // Start with first requestor as highest priority
        else
            mask <= '{mask[1], mask[2], mask[0]};  // Rotate mask
    end

    // Mask the requests to prioritize round-robin
    always_comb begin
        for (int i = 0; i < 3; i++)
            masked_req_arb[i] = req_arb[i] & mask[i];
    end
    
    // gnt_arb logic: Give priority to lowest set bit in masked request
    always_comb begin
        next_gnt_arb = '{0, 0, 0};
        for (int i = 0; i < 3; i++) begin
            if (masked_req_arb[i]) begin
                next_gnt_arb[i] = 1'b1;
                break;
            end
        end
    end
    
    // If no masked request is valid, gnt_arb based on raw request (unmasked)
    always_comb begin
        gnt_arb = next_gnt_arb;
        if (gnt_arb == '{0, 0, 0}) begin
            for (int i = 0; i < 3; i++) begin
                if (req_arb[i]) begin
                    gnt_arb[i] = 1'b1;
                    break;
                end
            end
        end
    end
    
endmodule
