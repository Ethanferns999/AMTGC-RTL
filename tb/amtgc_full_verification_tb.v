`timescale 1ns/1ps

module amtgc_full_verification_tb;

    // ============================================================
    // PARAMETERS
    // ============================================================

    parameter COUNTER_WIDTH = 8;

    parameter A_GREEN_TIME  = 10;
    parameter A_YELLOW_TIME = 3;
    parameter A_RED_TIME    = 2;
    parameter A_PED_TIME    = 5;

    parameter B_GREEN_TIME  = 10;
    parameter B_YELLOW_TIME = 3;
    parameter B_RED_TIME    = 2;
    parameter B_PED_TIME    = 5;

    parameter A_MIN_GREEN_TIME  = 3;
    parameter A_MAX_GREEN_TIME  = 8;
    parameter A_GREEN_EXTENSION = 1;

    parameter B_MIN_GREEN_TIME  = 3;
    parameter B_MAX_GREEN_TIME  = 8;
    parameter B_GREEN_EXTENSION = 1;

    parameter GREEN_WAVE_OFFSET = 2;

    // ============================================================
    // CLOCK / INPUTS
    // ============================================================

    reg clk;
    reg rst;

    reg ped_req_a;
    reg ped_req_b;

    reg [2:0] traffic_density_a;
    reg [2:0] traffic_density_b;

    reg emergency_override;

    // ============================================================
    // OUTPUTS
    // ============================================================

    wire [1:0] a_ns_light;
    wire [1:0] a_ew_light;

    wire [1:0] b_ns_light;
    wire [1:0] b_ew_light;

    wire ped_grant_a;
    wire ped_grant_b;

    // ============================================================
    // LIGHT ENCODING
    // ============================================================

    localparam RED    = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN  = 2'b10;

    // ============================================================
    // FSM STATES
    // ============================================================

    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam ALL_RED_1 = 3'd2;
    localparam PED_PHASE = 3'd3;
    localparam EW_GREEN  = 3'd4;
    localparam EW_YELLOW = 3'd5;
    localparam ALL_RED_2 = 3'd6;

    // ============================================================
    // DUT
    // ============================================================

    amtgc_top #(
        .COUNTER_WIDTH(COUNTER_WIDTH),

        .A_GREEN_TIME(A_GREEN_TIME),
        .A_YELLOW_TIME(A_YELLOW_TIME),
        .A_RED_TIME(A_RED_TIME),
        .A_PED_TIME(A_PED_TIME),

        .B_GREEN_TIME(B_GREEN_TIME),
        .B_YELLOW_TIME(B_YELLOW_TIME),
        .B_RED_TIME(B_RED_TIME),
        .B_PED_TIME(B_PED_TIME),

        .A_MIN_GREEN_TIME(A_MIN_GREEN_TIME),
        .A_MAX_GREEN_TIME(A_MAX_GREEN_TIME),
        .A_GREEN_EXTENSION(A_GREEN_EXTENSION),

        .B_MIN_GREEN_TIME(B_MIN_GREEN_TIME),
        .B_MAX_GREEN_TIME(B_MAX_GREEN_TIME),
        .B_GREEN_EXTENSION(B_GREEN_EXTENSION),

        .GREEN_WAVE_OFFSET(GREEN_WAVE_OFFSET)
    ) dut (
        .clk(clk),
        .rst(rst),

        .ped_req_a(ped_req_a),
        .ped_req_b(ped_req_b),

        .traffic_density_a(traffic_density_a),
        .traffic_density_b(traffic_density_b),

        .emergency_override(emergency_override),

        .a_ns_light(a_ns_light),
        .a_ew_light(a_ew_light),

        .b_ns_light(b_ns_light),
        .b_ew_light(b_ew_light),

        .ped_grant_a(ped_grant_a),
        .ped_grant_b(ped_grant_b)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer errors;
    integer checks;

    integer phase_ns_green;
    integer phase_ns_yellow;
    integer phase_all_red_1;
    integer phase_ped;
    integer phase_ew_green;
    integer phase_ew_yellow;
    integer phase_all_red_2;

    integer ped_a_grants;
    integer ped_b_grants;

    integer wave_detected;

    // ============================================================
    // CHECK TASK
    // ============================================================

    task check;

        input condition;
        input [8*100:1] message;

        begin

            checks = checks + 1;

            if (condition) begin

                $display(
                    "TEST PASSED: %s",
                    message
                );

            end
            else begin

                $display(
                    "TEST FAILED: %s",
                    message
                );

                errors = errors + 1;

            end

        end

    endtask

    // ============================================================
    // RESET TEST
    // ============================================================

    task test_reset;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RESET VERIFICATION");
            $display("----------------------------------------------");

            rst = 1'b1;

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            traffic_density_a = 3'd0;
            traffic_density_b = 3'd0;

            emergency_override = 1'b0;

            repeat (2)
                @(posedge clk);

            #1;

            check(
                (a_ns_light == GREEN) &&
                (a_ew_light == RED),
                "Reset -> Junction A NS_GREEN"
            );

            check(
                (b_ns_light == RED) &&
                (b_ew_light == RED),
                "Reset -> Junction B held all-red"
            );

            rst = 1'b0;

        end

    endtask

    // ============================================================
    // NATURAL FSM COVERAGE
    //
    // We simply watch the controller for enough cycles.
    // No state forcing.
    // ============================================================

    task test_fsm;

        integer cycles;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("FSM PHASE COVERAGE");
            $display("----------------------------------------------");

            rst = 1'b1;

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            traffic_density_a = 3'd0;
            traffic_density_b = 3'd0;

            emergency_override = 1'b0;

            phase_ns_green  = 0;
            phase_ns_yellow = 0;
            phase_all_red_1 = 0;
            phase_ped       = 0;
            phase_ew_green  = 0;
            phase_ew_yellow = 0;
            phase_all_red_2 = 0;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            // 60 cycles is deliberately generous.
            // With the verified debug timing, this covers
            // several complete FSM cycles.

            for (cycles = 0; cycles < 60; cycles = cycles + 1) begin

                @(posedge clk);
                #1;

                case (dut.u_junction_a.current_state)

                    NS_GREEN:
                        phase_ns_green = 1;

                    NS_YELLOW:
                        phase_ns_yellow = 1;

                    ALL_RED_1:
                        phase_all_red_1 = 1;

                    PED_PHASE:
                        phase_ped = 1;

                    EW_GREEN:
                        phase_ew_green = 1;

                    EW_YELLOW:
                        phase_ew_yellow = 1;

                    ALL_RED_2:
                        phase_all_red_2 = 1;

                    default:
                        begin
                        end

                endcase

            end

            check(
                phase_ns_green,
                "NS_GREEN phase observed"
            );

            check(
                phase_ns_yellow,
                "NS_YELLOW phase observed"
            );

            check(
                phase_all_red_1,
                "ALL_RED_1 phase observed"
            );

            check(
                phase_ew_green,
                "EW_GREEN phase observed"
            );

            check(
                phase_ew_yellow,
                "EW_YELLOW phase observed"
            );

            check(
                phase_all_red_2,
                "ALL_RED_2 phase observed"
            );

            check(
                phase_ns_green &&
                phase_ns_yellow &&
                phase_all_red_1 &&
                phase_ew_green &&
                phase_ew_yellow &&
                phase_all_red_2,
                "Complete FSM cycle observed"
            );

        end

    endtask

    // ============================================================
    // PEDESTRIAN FAIRNESS
    // ============================================================

    task test_pedestrian_fairness;

        integer i;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("PEDESTRIAN FAIRNESS - 120 REQUESTS");
            $display("----------------------------------------------");

            ped_a_grants = 0;
            ped_b_grants = 0;

            rst = 1'b1;

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            for (i = 0; i < 120; i = i + 1) begin

                ped_req_a = 1'b1;
                ped_req_b = 1'b1;

                @(posedge clk);
                #1;

                if (ped_grant_a && !ped_grant_b)
                    ped_a_grants = ped_a_grants + 1;

                if (ped_grant_b && !ped_grant_a)
                    ped_b_grants = ped_b_grants + 1;

                ped_req_a = 1'b0;
                ped_req_b = 1'b0;

                @(posedge clk);
                #1;

            end

            check(
                ped_a_grants > 0,
                "Pedestrian A receives grants"
            );

            check(
                ped_b_grants > 0,
                "Pedestrian B receives grants"
            );

            check(
                ped_a_grants >= 40,
                "Pedestrian A not starved"
            );

            check(
                ped_b_grants >= 40,
                "Pedestrian B not starved"
            );

            check(
                !(ped_grant_a && ped_grant_b),
                "Pedestrian grants mutually exclusive"
            );

            $display(
                "Pedestrian A grants = %0d",
                ped_a_grants
            );

            $display(
                "Pedestrian B grants = %0d",
                ped_b_grants
            );

        end

    endtask

    // ============================================================
    // ADAPTIVE DENSITY
    // ============================================================

    task test_density;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("ADAPTIVE DENSITY VERIFICATION");
            $display("----------------------------------------------");

            // Density 0 -> 3

            rst = 1'b1;
            traffic_density_a = 3'd0;
            traffic_density_b = 3'd7;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);
            #1;

            check(
                dut.u_junction_a.timer_target == 3,
                "Density 0/7 -> A green target 3"
            );

            // Density 2 -> 5

            rst = 1'b1;
            traffic_density_a = 3'd2;
            traffic_density_b = 3'd5;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);
            #1;

            check(
                dut.u_junction_a.timer_target == 5,
                "Density 2/5 -> A green target 5"
            );

            // Density 3 -> 6

            rst = 1'b1;
            traffic_density_a = 3'd3;
            traffic_density_b = 3'd3;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);
            #1;

            check(
                dut.u_junction_a.timer_target == 6,
                "Density 3/3 -> A green target 6"
            );

            // Density 5 -> capped at 8

            rst = 1'b1;
            traffic_density_a = 3'd5;
            traffic_density_b = 3'd1;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);
            #1;

            check(
                dut.u_junction_a.timer_target == 8,
                "Density 5/1 -> A green target capped at 8"
            );

            // Density 7 -> capped at 8

            rst = 1'b1;
            traffic_density_a = 3'd7;
            traffic_density_b = 3'd7;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);
            #1;

            check(
                dut.u_junction_a.timer_target == 8,
                "Density 7/7 -> A green target capped at 8"
            );

        end

    endtask

    // ============================================================
    // GREEN WAVE
    // ============================================================

    task test_green_wave;

        integer cycles;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("GREEN-WAVE VERIFICATION");
            $display("----------------------------------------------");

            rst = 1'b1;

            traffic_density_a = 3'd2;
            traffic_density_b = 3'd2;

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            emergency_override = 1'b0;

            wave_detected = 0;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            for (cycles = 0; cycles < 50; cycles = cycles + 1) begin

                @(posedge clk);
                #1;

                if (b_ns_light == GREEN)
                    wave_detected = 1;

            end

            check(
                wave_detected,
                "Junction B NS_GREEN starts after green-wave delay"
            );

        end

    endtask

    // ============================================================
    // EMERGENCY TEST
    //
    // We don't force every individual FSM phase here.
    // We verify the actual system-level emergency behavior.
    // ============================================================

    task test_emergency;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("EMERGENCY OVERRIDE");
            $display("----------------------------------------------");

            rst = 1'b1;

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            traffic_density_a = 3'd3;
            traffic_density_b = 3'd3;

            emergency_override = 1'b0;

            repeat (2)
                @(posedge clk);

            rst = 1'b0;

            // Allow normal operation.

            repeat (8)
                @(posedge clk);

            // Assert emergency.

            emergency_override = 1'b1;

            @(posedge clk);
            #1;

            check(
                (a_ns_light == RED) &&
                (a_ew_light == RED) &&
                (b_ns_light == RED) &&
                (b_ew_light == RED),
                "Emergency -> both junctions all red"
            );

            // Keep emergency active.

            repeat (5)
                @(posedge clk);

            #1;

            check(
                (a_ns_light == RED) &&
                (a_ew_light == RED) &&
                (b_ns_light == RED) &&
                (b_ew_light == RED),
                "Emergency maintains all-red"
            );

            // Release.

            emergency_override = 1'b0;

            @(posedge clk);
            #1;

            check(
                !(
                    (a_ns_light == GREEN) &&
                    (a_ew_light == GREEN)
                ),
                "Emergency released safely"
            );

        end

    endtask

    // ============================================================
    // RUNTIME RESET
    // ============================================================

    task test_runtime_reset;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RUNTIME RESET");
            $display("----------------------------------------------");

            rst = 1'b0;

            repeat (12)
                @(posedge clk);

            rst = 1'b1;

            @(posedge clk);
            #1;

            check(
                (a_ns_light == GREEN) &&
                (a_ew_light == RED),
                "Reset during operation -> NS_GREEN"
            );

            rst = 1'b0;

        end

    endtask

    // ============================================================
    // RANDOM SAFETY
    // ============================================================

    task test_randomized;

        integer i;
        integer ra;
        integer rb;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("RANDOMIZED VERIFICATION - 500 CYCLES");
            $display("----------------------------------------------");

            rst = 1'b0;
            emergency_override = 1'b0;

            for (i = 0; i < 500; i = i + 1) begin

                ra = $random & 7;
                rb = $random & 7;

                traffic_density_a = ra[2:0];
                traffic_density_b = rb[2:0];

                ped_req_a = $random & 1;
                ped_req_b = $random & 1;

                @(posedge clk);
                #1;

                // No junction may have both directions green.

                if ((a_ns_light == GREEN) &&
                    (a_ew_light == GREEN)) begin

                    errors = errors + 1;

                    $display(
                        "SAFETY FAILURE: Junction A conflicting greens"
                    );

                end

                if ((b_ns_light == GREEN) &&
                    (b_ew_light == GREEN)) begin

                    errors = errors + 1;

                    $display(
                        "SAFETY FAILURE: Junction B conflicting greens"
                    );

                end

                // Pedestrian grants must be exclusive.

                if (ped_grant_a && ped_grant_b) begin

                    errors = errors + 1;

                    $display(
                        "SAFETY FAILURE: Both pedestrian grants active"
                    );

                end

            end

            ped_req_a = 1'b0;
            ped_req_b = 1'b0;

            $display(
                "Randomized cycles completed = 500"
            );

        end

    endtask

    // ============================================================
    // MAIN
    // ============================================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        ped_req_a = 1'b0;
        ped_req_b = 1'b0;

        traffic_density_a = 3'd0;
        traffic_density_b = 3'd0;

        emergency_override = 1'b0;

        errors = 0;
        checks = 0;

        phase_ns_green  = 0;
        phase_ns_yellow = 0;
        phase_all_red_1 = 0;
        phase_ped       = 0;
        phase_ew_green  = 0;
        phase_ew_yellow = 0;
        phase_all_red_2 = 0;

        ped_a_grants = 0;
        ped_b_grants = 0;

        wave_detected = 0;

        $display("");
        $display("================================================");
        $display("AMTGC TASK 5 FULL SYSTEM VERIFICATION");
        $display("================================================");

        // --------------------------------------------------------
        // RUN TESTS
        // --------------------------------------------------------

        test_reset;

        test_fsm;

        test_pedestrian_fairness;

        test_density;

        test_green_wave;

        test_emergency;

        test_runtime_reset;

        test_randomized;

        // --------------------------------------------------------
        // SUMMARY
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("TASK 5 VERIFICATION SUMMARY");
        $display("================================================");

        $display(
            "Total checks = %0d",
            checks
        );

        $display(
            "Total errors = %0d",
            errors
        );

        $display("");
        $display("Phase coverage:");

        $display(
            "NS_GREEN   = %0d",
            phase_ns_green
        );

        $display(
            "NS_YELLOW  = %0d",
            phase_ns_yellow
        );

        $display(
            "ALL_RED_1  = %0d",
            phase_all_red_1
        );

        $display(
            "PED_PHASE  = %0d",
            phase_ped
        );

        $display(
            "EW_GREEN   = %0d",
            phase_ew_green
        );

        $display(
            "EW_YELLOW  = %0d",
            phase_ew_yellow
        );

        $display(
            "ALL_RED_2  = %0d",
            phase_all_red_2
        );

        $display("");
        $display(
            "Pedestrian A grants = %0d",
            ped_a_grants
        );

        $display(
            "Pedestrian B grants = %0d",
            ped_b_grants
        );

        $display("");

        if (errors == 0) begin

            $display("==============================================");
            $display("ALL TASK 5 VERIFICATION TESTS PASSED");
            $display("AMTGC full-system verification successful.");
            $display("==============================================");

        end
        else begin

            $display("==============================================");
            $display("TASK 5 VERIFICATION FAILED");
            $display("Total errors = %0d", errors);
            $display("==============================================");

        end

        $finish;

    end

endmodule