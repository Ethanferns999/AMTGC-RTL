`timescale 1ns/1ps

module amtgc_top_tb;

    parameter COUNTER_WIDTH = 4;

    parameter A_GREEN_TIME  = 4;
    parameter A_YELLOW_TIME = 2;
    parameter A_RED_TIME    = 1;
    parameter A_PED_TIME    = 2;

    parameter B_GREEN_TIME  = 4;
    parameter B_YELLOW_TIME = 2;
    parameter B_RED_TIME    = 1;
    parameter B_PED_TIME    = 2;

    parameter GREEN_WAVE_OFFSET = 2;

    reg clk;
    reg rst;

    reg ped_req_a;
    reg ped_req_b;
    reg emergency_override;

    wire [1:0] a_ns_light;
    wire [1:0] a_ew_light;
    wire [1:0] b_ns_light;
    wire [1:0] b_ew_light;

    wire ped_grant_a;
    wire ped_grant_b;

    integer errors;
    integer grant_a_count;
    integer grant_b_count;

    integer b_green_seen;
    integer b_green_cycle;

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

        .GREEN_WAVE_OFFSET(GREEN_WAVE_OFFSET)
    ) dut (
        .clk(clk),
        .rst(rst),

        .ped_req_a(ped_req_a),
        .ped_req_b(ped_req_b),

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
    // TESTS
    // ============================================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        ped_req_a = 1'b0;
        ped_req_b = 1'b0;

        emergency_override = 1'b0;

        errors = 0;
        grant_a_count = 0;
        grant_b_count = 0;

        b_green_seen = 0;
        b_green_cycle = -1;

        $display("");
        $display("==============================================");
        $display(" AMTGC SYSTEM INTEGRATION TESTBENCH");
        $display("==============================================");
        $display("");

        // ========================================================
        // TEST 1: RESET
        // ========================================================

        repeat (2)
            @(posedge clk);

        #1;

        if ((a_ns_light === GREEN) &&
            (a_ew_light === RED)) begin

            $display("TEST PASSED: Reset -> Junction A NS_GREEN");

        end
        else begin

            $display("TEST FAILED: Reset -> Junction A NS_GREEN");
            errors = errors + 1;

        end

        if ((b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display("TEST PASSED: Reset -> Junction B held all-red");

        end
        else begin

            $display("TEST FAILED: Reset -> Junction B held all-red");
            errors = errors + 1;

        end

        // ========================================================
        // RELEASE RESET
        // ========================================================

        rst = 1'b0;

        #1;

        // ========================================================
        // TEST 2: A INITIAL GREEN
        // ========================================================

        if ((a_ns_light === GREEN) &&
            (a_ew_light === RED)) begin

            $display("TEST PASSED: Junction A initial NS_GREEN");

        end
        else begin

            $display("TEST FAILED: Junction A initial NS_GREEN");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 3: B INITIALLY RED
        // ========================================================

        if ((b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display("TEST PASSED: Junction B initial green-wave hold");

        end
        else begin

            $display("TEST FAILED: Junction B initial green-wave hold");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 4: GREEN WAVE
        //
        // Sample every clock for a bounded number of cycles.
        // ========================================================

        b_green_seen = 0;
        b_green_cycle = -1;

        repeat (6) begin

            @(posedge clk);
            #1;

            if ((b_ns_light === GREEN) &&
                (b_ew_light === RED) &&
                (b_green_seen == 0)) begin

                b_green_seen = 1;
                b_green_cycle = 1;

                $display(
                    "B NS_GREEN detected at simulation time %0d ns",
                    $time
                );

            end

        end

        if (b_green_seen == 1) begin

            $display(
                "TEST PASSED: Junction B NS_GREEN begins after startup offset"
            );

        end
        else begin

            $display(
                "TEST FAILED: Junction B never entered NS_GREEN"
            );

            errors = errors + 1;

        end

        // ========================================================
        // TEST 5: NO CONFLICTING GREENS
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

            $display("TEST PASSED: No conflicting green outputs");

        end

        // ========================================================
        // Allow system to operate
        // ========================================================

        repeat (8)
            @(posedge clk);

        #1;

        // ========================================================
        // TEST 6: SIMULTANEOUS PEDESTRIAN REQUEST
        // ========================================================

        ped_req_a = 1'b1;
        ped_req_b = 1'b1;

        @(posedge clk);
        #1;

        if ((ped_grant_a === 1'b1) &&
            (ped_grant_b === 1'b0)) begin

            $display("TEST PASSED: Simultaneous request -> A");
            grant_a_count = grant_a_count + 1;

        end
        else if ((ped_grant_a === 1'b0) &&
                 (ped_grant_b === 1'b1)) begin

            $display("TEST PASSED: Simultaneous request -> B");
            grant_b_count = grant_b_count + 1;

        end
        else begin

            $display("TEST FAILED: Invalid pedestrian grant");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 7: REPEATED SIMULTANEOUS REQUESTS
        // ========================================================

        repeat (6) begin

            @(posedge clk);
            #1;

            if ((ped_grant_a === 1'b1) &&
                (ped_grant_b === 1'b0)) begin

                grant_a_count = grant_a_count + 1;

            end
            else if ((ped_grant_a === 1'b0) &&
                     (ped_grant_b === 1'b1)) begin

                grant_b_count = grant_b_count + 1;

            end

        end

        if ((grant_a_count > 0) &&
            (grant_b_count > 0)) begin

            $display(
                "TEST PASSED: Pedestrian arbitration prevents starvation"
            );

            $display("           A grants = %d", grant_a_count);
            $display("           B grants = %d", grant_b_count);

        end
        else begin

            $display("TEST FAILED: Pedestrian starvation detected");
            errors = errors + 1;

        end

        // ========================================================
        // Remove requests
        // ========================================================

        ped_req_a = 1'b0;
        ped_req_b = 1'b0;

        @(posedge clk);
        #1;

        if ((ped_grant_a === 1'b0) &&
            (ped_grant_b === 1'b0)) begin

            $display("TEST PASSED: Pedestrian grants clear");

        end
        else begin

            $display("TEST FAILED: Pedestrian grants did not clear");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 8: EMERGENCY OVERRIDE
        // ========================================================

        emergency_override = 1'b1;

        @(posedge clk);
        #1;

        if ((a_ns_light === RED) &&
            (a_ew_light === RED) &&
            (b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display("TEST PASSED: Emergency -> both junctions all-red");

        end
        else begin

            $display("TEST FAILED: Emergency all-red response");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 9: EMERGENCY HOLD
        // ========================================================

        repeat (3)
            @(posedge clk);

        #1;

        if ((a_ns_light === RED) &&
            (a_ew_light === RED) &&
            (b_ns_light === RED) &&
            (b_ew_light === RED)) begin

            $display("TEST PASSED: Emergency maintains all-red");

        end
        else begin

            $display("TEST FAILED: Emergency all-red hold");
            errors = errors + 1;

        end

    // ========================================================
// TEST 10: EMERGENCY RELEASE
//
// After emergency is released, the system must resume from
// a valid traffic state. A valid green/yellow phase is allowed.
// Conflicting greens are never allowed.
// ========================================================

emergency_override = 1'b0;

@(posedge clk);
#1;

if (((a_ns_light === GREEN) &&
     (a_ew_light === GREEN)) ||
    ((b_ns_light === GREEN) &&
     (b_ew_light === GREEN))) begin

    $display("TEST FAILED: Conflicting lights after emergency");

    errors = errors + 1;

end
else begin

    $display("TEST PASSED: Emergency released to valid traffic state");

end

        // ========================================================
        // TEST 11: SYSTEM RECOVERY
        // ========================================================

        repeat (6)
            @(posedge clk);

        #1;

        if ((a_ns_light !== RED) ||
            (a_ew_light !== RED) ||
            (b_ns_light !== RED) ||
            (b_ew_light !== RED)) begin

            $display("TEST PASSED: System resumes after emergency");

        end
        else begin

            $display("TEST FAILED: System did not resume");
            errors = errors + 1;

        end

        // ========================================================
        // TEST 12: FINAL SAFETY CHECK
        // ========================================================

        if ((a_ns_light === GREEN) &&
            (a_ew_light === GREEN)) begin

            $display("TEST FAILED: Junction A simultaneous greens");
            errors = errors + 1;

        end
        else if ((b_ns_light === GREEN) &&
                 (b_ew_light === GREEN)) begin

            $display("TEST FAILED: Junction B simultaneous greens");
            errors = errors + 1;

        end
        else begin

            $display("TEST PASSED: Junction light safety maintained");

        end

        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(" ALL AMTGC INTEGRATION TESTS PASSED");
            $display(" System-level integration successful.");

        end
        else begin

            $display(" AMTGC INTEGRATION TEST FAILED");
            $display(" Total errors = %d", errors);

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule