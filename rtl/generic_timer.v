module generic_timer #(
    parameter COUNTER_WIDTH = 8
) (
    input  wire                     clk,
    input  wire                     rst,
    input  wire                     start,
    input  wire [COUNTER_WIDTH-1:0] count_target,
    output reg                      done
);

    reg [COUNTER_WIDTH-1:0] counter;
    reg                     active;

    always @(posedge clk) begin

        if (rst) begin
            counter <= '0;
            active  <= 1'b0;
            done    <= 1'b0;
        end

        else begin
            // done is a one-cycle pulse
            done <= 1'b0;

            if (!active) begin

                // IDLE: wait for start
                if (start) begin

                    if (count_target == 0) begin
                        // Zero target completes immediately
                        counter <= '0;
                        done    <= 1'b1;
                        active  <= 1'b0;
                    end

                    else begin
                        // First clock counts as cycle 1
                        counter <= 1'b1;
                        active  <= 1'b1;
                    end

                end
            end

            else begin

                // COUNTING
                if (counter == count_target - 1'b1) begin
                    counter <= counter + 1'b1;
                    done    <= 1'b1;
                    active  <= 1'b0;
                end

                else begin
                    counter <= counter + 1'b1;
                end

            end
        end

    end

endmodule
