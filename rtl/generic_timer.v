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
        done <= 1'b0;

        if (!active) begin
            // idle
        end
        else begin
            // counting
        end
    end

end
endmodule