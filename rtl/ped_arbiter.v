
module ped_arbiter (
    input  wire clk,
    input  wire rst,

    input  wire req_a,
    input  wire req_b,

    output reg  grant_a,
    output reg  grant_b
);

    // 0 = A has priority for the next simultaneous request
    // 1 = B has priority for the next simultaneous request
    reg last_grant;

    localparam A = 1'b0;
    localparam B = 1'b1;

    // ------------------------------------------------------------
    // Remember which junction was most recently granted
    // ------------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin
            last_grant <= B;
        end

        else begin

            if (grant_a)
                last_grant <= A;

            else if (grant_b)
                last_grant <= B;

        end

    end

    // ------------------------------------------------------------
    // Round-robin arbitration
    // ------------------------------------------------------------

    always @(*) begin

        // Default: no grants
        grant_a = 1'b0;
        grant_b = 1'b0;

        case ({req_a, req_b})

            2'b00: begin
                // No requests
            end

            2'b10: begin
                // Only A requests
                grant_a = 1'b1;
            end

            2'b01: begin
                // Only B requests
                grant_b = 1'b1;
            end

            2'b11: begin

                if (last_grant == A)
                    grant_b = 1'b1;
                else
                    grant_a = 1'b1;

            end

            default: begin
                grant_a = 1'b0;
                grant_b = 1'b0;
            end

        endcase

    end

endmodule