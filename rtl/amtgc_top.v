module amtgc_top #(
    parameter COUNTER_WIDTH = 8,

    parameter A_GREEN_TIME  = 10,
    parameter A_YELLOW_TIME = 3,
    parameter A_RED_TIME    = 2,
    parameter A_PED_TIME    = 5,

    parameter B_GREEN_TIME  = 10,
    parameter B_YELLOW_TIME = 3,
    parameter B_RED_TIME    = 2,
    parameter B_PED_TIME    = 5,

    parameter GREEN_WAVE_OFFSET = 2
) (
    input wire clk,
    input wire rst,

    input wire ped_req_a,
    input wire ped_req_b,

    input wire emergency_override,

    output wire [1:0] a_ns_light,
    output wire [1:0] a_ew_light,

    output wire [1:0] b_ns_light,
    output wire [1:0] b_ew_light,

    output wire ped_grant_a,
    output wire ped_grant_b
);

    // ============================================================
    // Timer signals
    // ============================================================

    wire timer_start_a;
    wire timer_done_a;

    wire timer_start_b;
    wire timer_done_b;

    wire [COUNTER_WIDTH-1:0] timer_target_a;
    wire [COUNTER_WIDTH-1:0] timer_target_b;

    // ============================================================
    // Junction enable signals
    // ============================================================

    reg enable_a;
    reg enable_b;

    // ============================================================
    // Green-wave counter
    //
    // Junction A starts immediately.
    // Junction B is enabled after GREEN_WAVE_OFFSET cycles.
    // ============================================================

    reg [COUNTER_WIDTH-1:0] wave_counter;

    // ============================================================
    // Green-wave control
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            wave_counter <= {COUNTER_WIDTH{1'b0}};
            enable_a     <= 1'b1;
            enable_b     <= 1'b0;

        end

        else if (emergency_override) begin

            wave_counter <= {COUNTER_WIDTH{1'b0}};
            enable_a     <= 1'b0;
            enable_b     <= 1'b0;

        end

        else begin

            enable_a <= 1'b1;

            if (!enable_b) begin

                if (GREEN_WAVE_OFFSET == 0) begin

                    enable_b <= 1'b1;

                end

                else if (wave_counter >= GREEN_WAVE_OFFSET - 1) begin

                    enable_b <= 1'b1;

                end

                else begin

                    wave_counter <= wave_counter + 1'b1;

                end

            end

        end

    end

    // ============================================================
    // Pedestrian Arbiter
    // ============================================================

    ped_arbiter u_ped_arbiter (
        .clk      (clk),
        .rst      (rst),

        .req_a    (ped_req_a),
        .req_b    (ped_req_b),

        .grant_a  (ped_grant_a),
        .grant_b  (ped_grant_b)
    );

    // ============================================================
    // Junction A Controller
    // ============================================================

    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME(A_GREEN_TIME),
        .YELLOW_TIME(A_YELLOW_TIME),
        .RED_TIME(A_RED_TIME),
        .PED_TIME(A_PED_TIME)
    ) u_junction_a (
        .clk                (clk),
        .rst                (rst),
        .enable             (enable_a),
        .timer_done         (timer_done_a),
        .ped_grant          (ped_grant_a),
        .emergency_override (emergency_override),

        .timer_start        (timer_start_a),
        .timer_target       (timer_target_a),

        .ns_light           (a_ns_light),
        .ew_light           (a_ew_light)
    );

    // ============================================================
    // Junction A Timer
    // ============================================================

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_timer_a (
        .clk          (clk),
        .rst          (rst),
        .start        (timer_start_a),
        .count_target (timer_target_a),
        .done         (timer_done_a)
    );

    // ============================================================
    // Junction B Controller
    // ============================================================

    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME(B_GREEN_TIME),
        .YELLOW_TIME(B_YELLOW_TIME),
        .RED_TIME(B_RED_TIME),
        .PED_TIME(B_PED_TIME)
    ) u_junction_b (
        .clk                (clk),
        .rst                (rst),
        .enable             (enable_b),
        .timer_done         (timer_done_b),
        .ped_grant          (ped_grant_b),
        .emergency_override (emergency_override),

        .timer_start        (timer_start_b),
        .timer_target       (timer_target_b),

        .ns_light           (b_ns_light),
        .ew_light           (b_ew_light)
    );

    // ============================================================
    // Junction B Timer
    // ============================================================

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) u_timer_b (
        .clk          (clk),
        .rst          (rst),
        .start        (timer_start_b),
        .count_target (timer_target_b),
        .done         (timer_done_b)
    );

endmodule
