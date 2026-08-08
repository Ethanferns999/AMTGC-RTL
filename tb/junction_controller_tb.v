`timescale 1ns/1ps

module junction_controller_tb;

    // ============================================================
    // Test parameters
    // ============================================================

    parameter COUNTER_WIDTH = 4;

    parameter GREEN_TIME    = 3;
    parameter YELLOW_TIME   = 2;
    parameter RED_TIME      = 1;
    parameter PED_TIME      = 2;

    // ============================================================
    // Testbench signals
    // ============================================================

    reg clk;
    reg rst;
    reg timer_done;
    reg ped_grant;

    wire                     timer_start;
    wire [COUNTER_WIDTH-1:0] timer_target;
    wire [1:0]               ns_light;
    wire [1:0]               ew_light;

    // ============================================================
    // Light encodings
    // ============================================================

    localparam RED    = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN  = 2'b10;

    // ============================================================
    // Expected FSM states
    // These match junction_controller.v
    // ============================================================

    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam ALL_RED_1 = 3'd2;
    localparam PED_PHASE = 3'd3;
    localparam EW_GREEN  = 3'd4;
    localparam EW_YELLOW = 3'd5;
    localparam ALL_RED_2 = 3'd6;

    integer errors;

    // ============================================================
    // DUT
    // ============================================================

    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME(GREEN_TIME),
        .YELLOW_TIME(YELLOW_TIME),
        .RED_TIME(RED_TIME),
        .PED_TIME(PED_TIME)
    ) dut (
        .clk(clk),
        .rst(rst),
        .timer_done(timer_done),
        .ped_grant(ped_grant),
        .timer_start(timer_start),
        .timer_target(timer_target),
        .ns_light(ns_light),
        .ew_light(ew_light)
    );

    // ============================================================
    // Clock
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // Check current FSM state
    // ============================================================

    task check_state;
        input [2:0] expected_state;
        input [8*40-1:0] test_name;

        begin

            if (dut.current_state !== expected_state) begin

                $display("TEST FAILED: %s", test_name);
                $display("  Expected state = %d", expected_state);
                $display("  Actual state   = %d", dut.current_state);

                errors = errors + 1;

            end

            else begin

                $display("TEST PASSED: %s", test_name);

            end

        end
    endtask

    // ============================================================
    // Check traffic light outputs
    // ============================================================

    task check_lights;
        input [1:0] expected_ns;
        input [1:0] expected_ew;
        input [8*40-1:0] test_name;

        begin

            if ((ns_light !== expected_ns) ||
                (ew_light !== expected_ew)) begin

                $display("TEST FAILED: %s", test_name);

                $display("  Expected NS = %b, EW = %b",
                         expected_ns, expected_ew);

                $display("  Actual   NS = %b, EW = %b",
                         ns_light, ew_light);

                errors = errors + 1;

            end

            else begin

                $display("TEST PASSED: %s", test_name);

            end

        end
    endtask

    // ============================================================
    // Check timer target
    // ============================================================

    task check_timer_target;
        input [COUNTER_WIDTH-1:0] expected_target;
        input [8*40-1:0] test_name;

        begin

            if (timer_target !== expected_target) begin

                $display("TEST FAILED: %s", test_name);

                $display("  Expected timer target = %d",
                         expected_target);

                $display("  Actual timer target   = %d",
                         timer_target);

                errors = errors + 1;

            end

            else begin

                $display("TEST PASSED: %s", test_name);

            end

        end
    endtask

    // ============================================================
    // Check timer start pulse
    // ============================================================

    task check_timer_start;
        input expected_start;
        input [8*40-1:0] test_name;

        begin

            if (timer_start !== expected_start) begin

                $display("TEST FAILED: %s", test_name);

                $display("  Expected timer_start = %b",
                         expected_start);

                $display("  Actual timer_start   = %b",
                         timer_start);

                errors = errors + 1;

            end

            else begin

                $display("TEST PASSED: %s", test_name);

            end

        end

    endtask

    // ============================================================
    // Main test sequence
    // ============================================================

    initial begin

        clk        = 1'b0;
        rst        = 1'b1;
        timer_done = 1'b0;
        ped_grant  = 1'b0;
        errors     = 0;

        $display("");
        $display("==============================================");
        $display(" AMTGC JUNCTION CONTROLLER TESTBENCH");
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // TEST 1: Reset
        // --------------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        check_state(NS_GREEN, "Reset -> NS_GREEN");

        check_lights(
            GREEN,
            RED,
            "Reset -> NS_GREEN light outputs"
        );

        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------

        rst = 1'b0;

        #1;

        // --------------------------------------------------------
        // TEST 2: Initial timer start pulse
        // --------------------------------------------------------

        check_timer_start(
            1'b1,
            "Initial NS_GREEN timer start"
        );

        check_timer_target(
            GREEN_TIME,
            "NS_GREEN timer target"
        );

        // --------------------------------------------------------
        // TEST 3: Timer start should not remain high
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        check_timer_start(
            1'b0,
            "Timer start is one-cycle pulse"
        );

        // --------------------------------------------------------
        // TEST 4: NS_GREEN holds while timer_done = 0
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        check_state(
            NS_GREEN,
            "NS_GREEN holds without timer_done"
        );

        check_lights(
            GREEN,
            RED,
            "NS_GREEN output"
        );

        // --------------------------------------------------------
        // TEST 5: NS_GREEN -> NS_YELLOW
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            NS_YELLOW,
            "NS_GREEN -> NS_YELLOW"
        );

        check_lights(
            YELLOW,
            RED,
            "NS_YELLOW output"
        );

        check_timer_target(
            YELLOW_TIME,
            "NS_YELLOW timer target"
        );

        check_timer_start(
            1'b1,
            "NS_YELLOW timer start"
        );

        // --------------------------------------------------------
        // TEST 6: Timer start returns low
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        check_timer_start(
            1'b0,
            "NS_YELLOW timer start pulse width"
        );

        // --------------------------------------------------------
        // TEST 7: NS_YELLOW -> ALL_RED_1
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            ALL_RED_1,
            "NS_YELLOW -> ALL_RED_1"
        );

        check_lights(
            RED,
            RED,
            "ALL_RED_1 output"
        );

        check_timer_target(
            RED_TIME,
            "ALL_RED_1 timer target"
        );

        // --------------------------------------------------------
        // TEST 8: Pedestrian request must not bypass all-red
        // --------------------------------------------------------

        ped_grant = 1'b1;

        // Timer has NOT completed yet
        @(posedge clk);
        #1;

        check_state(
            ALL_RED_1,
            "Pedestrian grant cannot bypass all-red"
        );

        check_lights(
            RED,
            RED,
            "All-red maintained during pedestrian wait"
        );

        // --------------------------------------------------------
        // TEST 9: ALL_RED_1 -> PED_PHASE
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            PED_PHASE,
            "ALL_RED_1 -> PED_PHASE"
        );

        check_lights(
            RED,
            RED,
            "PED_PHASE output"
        );

        check_timer_target(
            PED_TIME,
            "PED_PHASE timer target"
        );

        // --------------------------------------------------------
        // TEST 10: PED_PHASE -> EW_GREEN
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            EW_GREEN,
            "PED_PHASE -> EW_GREEN"
        );

        check_lights(
            RED,
            GREEN,
            "EW_GREEN output"
        );

        check_timer_target(
            GREEN_TIME,
            "EW_GREEN timer target"
        );

        // Pedestrian grant no longer matters
        ped_grant = 1'b0;

        // --------------------------------------------------------
        // TEST 11: EW_GREEN holds
        // --------------------------------------------------------

        @(posedge clk);
        #1;

        check_state(
            EW_GREEN,
            "EW_GREEN holds without timer_done"
        );

        check_lights(
            RED,
            GREEN,
            "EW_GREEN remains active"
        );

        // --------------------------------------------------------
        // TEST 12: EW_GREEN -> EW_YELLOW
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            EW_YELLOW,
            "EW_GREEN -> EW_YELLOW"
        );

        check_lights(
            RED,
            YELLOW,
            "EW_YELLOW output"
        );

        check_timer_target(
            YELLOW_TIME,
            "EW_YELLOW timer target"
        );

        // --------------------------------------------------------
        // TEST 13: EW_YELLOW -> ALL_RED_2
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            ALL_RED_2,
            "EW_YELLOW -> ALL_RED_2"
        );

        check_lights(
            RED,
            RED,
            "ALL_RED_2 output"
        );

        check_timer_target(
            RED_TIME,
            "ALL_RED_2 timer target"
        );

        // --------------------------------------------------------
        // TEST 14: ALL_RED_2 -> NS_GREEN
        // --------------------------------------------------------

        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        check_state(
            NS_GREEN,
            "ALL_RED_2 -> NS_GREEN"
        );

        check_lights(
            GREEN,
            RED,
            "NS_GREEN after complete cycle"
        );

        check_timer_target(
            GREEN_TIME,
            "NS_GREEN timer target after cycle"
        );

        check_timer_start(
            1'b1,
            "NS_GREEN timer restart"
        );

        // --------------------------------------------------------
        // TEST 15: Pedestrian grant during NS_GREEN must not
        // interrupt traffic
        // --------------------------------------------------------

        ped_grant = 1'b1;

        @(posedge clk);
        #1;

        check_state(
            NS_GREEN,
            "Pedestrian request cannot interrupt NS_GREEN"
        );

        check_lights(
            GREEN,
            RED,
            "NS_GREEN maintained despite pedestrian request"
        );

        // --------------------------------------------------------
        // Clear pedestrian request
        // --------------------------------------------------------

        ped_grant = 1'b0;

        // --------------------------------------------------------
        // TEST 16: Reset during operation
        // --------------------------------------------------------

        rst = 1'b1;

        @(posedge clk);
        #1;

        check_state(
            NS_GREEN,
            "Reset during operation -> NS_GREEN"
        );

        check_lights(
            GREEN,
            RED,
            "Reset output -> NS_GREEN"
        );

        rst = 1'b0;

        // --------------------------------------------------------
        // TEST 17: No direct green-to-green transition
        // --------------------------------------------------------

        // Start from NS_GREEN after reset
        timer_done = 1'b1;

        @(posedge clk);
        #1;

        timer_done = 1'b0;

        if (dut.current_state === EW_GREEN) begin

            $display(
                "TEST FAILED: Direct NS_GREEN -> EW_GREEN transition"
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "TEST PASSED: No direct green-to-green transition"
            );

        end

        // --------------------------------------------------------
// TEST 18: Parameterization check
// Controller is currently in NS_YELLOW, so verify
// YELLOW_TIME instead.
// --------------------------------------------------------

if (timer_target !== YELLOW_TIME) begin

    $display(
        "TEST FAILED: Parameterized YELLOW_TIME target"
    );

    $display(
        "Expected = %d, Actual = %d",
        YELLOW_TIME,
        timer_target
    );

    errors = errors + 1;

end

else begin

    $display(
        "TEST PASSED: Parameterized YELLOW_TIME target"
    );

end

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(" ALL TESTS PASSED");
            $display(" Controller verification successful.");

        end

        else begin

            $display(" TEST FAILED");
            $display(" Total errors = %d", errors);

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule