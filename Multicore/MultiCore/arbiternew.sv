module arbiter(
    input wire clk,rst,
    input wire req_arb[3],
    output reg gnt_arb[3]
);

    reg mask[3];
    reg masked_req_arb[3];
    reg next_gnt_arb[3];

    always_ff @(posedge clk) begin
        if(rst) begin
            mask <= '{1,0,0};
        end
        else begin
            mask <= '{mask[1],mask[2],mask[0]};
        end
    end

    always_comb begin
        for(int i = 0; i < 3; i++) begin
            masked_req_arb[i] = req_arb[i] & mask[i];
        end 
    end

    always_comb begin
        next_gnt_arb = '{0,0,0};
        for(int i = 0; i < 3; i++) begin
            if(masked_req_arb[i]) begin
                next_gnt_arb[i] = 1'b1;
                break;
            end
        end
    end

    always_comb begin
        gnt_arb = next_gnt_arb
        if(gnt_arb == '{0,0,0}) begin
            for(int i = 0; i < 3; i++) begin
                if(req_arb[i]) begin
                    gnt_arb[i] = 1'b1;
                    break;
                end
            end
        end
    end

endmodule 