`timescale 1ns/1ps

module amtgc_adaptive_integration_tb;

    parameter COUNTER_WIDTH = 8;

    parameter A_GREEN_TIME  = 10;
    parameter A_YELLOW_TIME = 2;
    parameter A_RED_TIME    = 1;
    parameter A_PED_TIME    = 2;

    parameter B_GREEN_TIME  = 10;
    parameter B_YELLOW_TIME = 2;
    parameter B_RED_TIME    = 1;
    parameter B_PED_TIME    = 2;

    parameter A_MIN_GREEN_TIME  = 3;
    parameter A_MAX_GREEN_TIME  = 8;
    parameter A_GREEN_EXTENSION = 1;

    parameter B_MIN_GREEN_TIME  = 3;
    parameter B_MAX_GREEN_TIME  = 8;
    parameter B_GREEN_EXTENSION = 1;

    parameter GREEN_WAVE_OFFSET = 2;

    reg clk;
    reg rst;

    reg ped_req_a;
    reg ped_req_b;

    reg [2:0] traffic_density_a;
    reg [2:0] traffic_density_b;

    reg emergency_override;

    wire [1:0] a_ns_light;
    wire [1:0] a_ew_light;
    wire [1:0] b_ns_light;
    wire [1:0] b_ew_light;

    wire ped_grant_a;
    wire ped_grant_b;

    integer errors;
    integer cycle_count;

    localparam RED    = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN  = 2'b10;

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
    // Clock
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // Test
    // ============================================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        ped_req_a = 1'b0;
        ped_req_b = 1'b0;

        // A = low traffic
        // B = high traffic

        traffic_density_a = 3'd0;
        traffic_density_b = 3'd7;

        emergency_override = 1'b0;

        errors = 0;
        cycle_count = 0;

        $display("");
        $display("==============================================");
        $display(" AMTGC TASK 4 ADAPTIVE INTEGRATION TEST");
        $display("==============================================");
        $display("");

        // ========================================================
        // TEST 1: Reset
        // ========================================================

        repeat (2)
            @(posedge clk);

        #1;

        if ((a_ns_light === GREEN) &&
            (a_ew_light === RED)) begin

            $display("TEST PASSED: Reset -> Junction A NS_GREEN");

        end
        else begin

            $display("TEST FAILED: Junction A reset state");
            errors = errors + 1;

        end

        if ((b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display("TEST PASSED: Junction B held for green wave");

        end
        else begin

            $display("TEST FAILED: Junction B reset state");
            errors = errors + 1;

        end

        rst = 1'b0;

        // ========================================================
        // TEST 2: Different traffic densities
        //
        // A density = 0 -> expected green = 3
        // B density = 7 -> expected green = 8
        // ========================================================

        @(posedge clk);
        #1;

        if (dut.u_junction_a.timer_target == 3) begin

            $display(
                "TEST PASSED: Junction A low density -> target 3"
            );

        end
        else begin

            $display(
                "TEST FAILED: Junction A expected target 3, got %0d",
                dut.u_junction_a.timer_target
            );

            errors = errors + 1;

        end

        // ========================================================
        // Wait for B to become active
        // B should start after the configured green-wave offset.
        // ========================================================

        cycle_count = 0;

        while ((b_ns_light !== GREEN) && (cycle_count < 10)) begin

            @(posedge clk);
            #1;

            cycle_count = cycle_count + 1;

        end

        if (b_ns_light === GREEN) begin

            $display(
                "TEST PASSED: Green-wave -> Junction B NS_GREEN"
            );

        end
        else begin

            $display(
                "TEST FAILED: Junction B did not enter NS_GREEN"
            );

            errors = errors + 1;

        end

        // ========================================================
        // TEST 3: B high-density green target
        // ========================================================

        if (dut.u_junction_b.timer_target == 8) begin

            $display(
                "TEST PASSED: Junction B high density -> target 8"
            );

        end
        else begin

            $display(
                "TEST FAILED: Junction B expected target 8, got %0d",
                dut.u_junction_b.timer_target
            );

            errors = errors + 1;

        end

        // ========================================================
        // TEST 4: No conflicting greens
        // ========================================================

        if ((a_ns_light === GREEN) &&
            (a_ew_light === GREEN)) begin

            $display("TEST FAILED: Junction A conflicting greens");
            errors = errors + 1;

        end
        else if ((b_ns_light === GREEN) &&
                 (b_ew_light === GREEN)) begin

            $display("TEST FAILED: Junction B conflicting greens");
            errors = errors + 1;

        end
        else begin

            $display("TEST PASSED: No conflicting greens");

        end

        // ========================================================
        // TEST 5: Pedestrian arbitration still works
        // ========================================================

        ped_req_a = 1'b1;
        ped_req_b = 1'b1;

        @(posedge clk);
        #1;

        if (((ped_grant_a === 1'b1) &&
             (ped_grant_b === 1'b0)) ||
            ((ped_grant_a === 1'b0) &&
             (ped_grant_b === 1'b1))) begin

            $display(
                "TEST PASSED: Adaptive system preserves pedestrian arbitration"
            );

        end
        else begin

            $display(
                "TEST FAILED: Pedestrian arbitration"
            );

            errors = errors + 1;

        end

        ped_req_a = 1'b0;
        ped_req_b = 1'b0;

        // ========================================================
        // TEST 6: Emergency override
        // ========================================================

        emergency_override = 1'b1;

        @(posedge clk);
        #1;

        if ((a_ns_light === RED) &&
            (a_ew_light === RED) &&
            (b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display(
                "TEST PASSED: Adaptive system emergency -> all red"
            );

        end
        else begin

            $display(
                "TEST FAILED: Emergency all-red"
            );

            errors = errors + 1;

        end

        // ========================================================
        // Emergency hold
        // ========================================================

        repeat (2)
            @(posedge clk);

        #1;

        if ((a_ns_light === RED) &&
            (a_ew_light === RED) &&
            (b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display(
                "TEST PASSED: Emergency maintains all-red"
            );

        end
        else begin

            $display(
                "TEST FAILED: Emergency all-red hold"
            );

            errors = errors + 1;

        end

        // ========================================================
        // Release emergency
        // ========================================================

        emergency_override = 1'b0;

        @(posedge clk);
        #1;

        if (((a_ns_light === GREEN) &&
             (a_ew_light === GREEN)) ||
            ((b_ns_light === GREEN) &&
             (b_ew_light === GREEN))) begin

            $display(
                "TEST FAILED: Conflicting greens after emergency"
            );

            errors = errors + 1;

        end
        else begin

            $display(
                "TEST PASSED: Emergency released safely"
            );

        end

        // ========================================================
        // Final result
        // ========================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(" ALL TASK 4 INTEGRATION TESTS PASSED");
            $display(" Adaptive AMTGC integration successful.");

        end
        else begin

            $display(" TASK 4 INTEGRATION TEST FAILED");
            $display(" Total errors = %0d", errors);

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
