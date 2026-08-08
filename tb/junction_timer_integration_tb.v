
`timescale 1ns/1ps

module junction_timer_integration_tb;

    // ============================================================
    // Parameters
    // ============================================================

    parameter COUNTER_WIDTH = 4;

    parameter GREEN_TIME  = 3;
    parameter YELLOW_TIME = 2;
    parameter RED_TIME    = 1;
    parameter PED_TIME    = 2;

    // ============================================================
    // Signals
    // ============================================================

    reg clk;
    reg rst;
    reg ped_grant;

    wire timer_start;
    wire [COUNTER_WIDTH-1:0] timer_target;
    wire timer_done;

    wire [1:0] ns_light;
    wire [1:0] ew_light;

    integer errors;

    // ============================================================
    // State encodings
    // ============================================================

    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam ALL_RED_1 = 3'd2;
    localparam PED_PHASE = 3'd3;
    localparam EW_GREEN  = 3'd4;
    localparam EW_YELLOW = 3'd5;
    localparam ALL_RED_2 = 3'd6;

    // ============================================================
    // DUT: Junction Controller
    // ============================================================

    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),
        .GREEN_TIME(GREEN_TIME),
        .YELLOW_TIME(YELLOW_TIME),
        .RED_TIME(RED_TIME),
        .PED_TIME(PED_TIME)
    ) controller (
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
    // DUT: Generic Timer
    // ============================================================

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) timer (
        .clk(clk),
        .rst(rst),
        .start(timer_start),
        .count_target(timer_target),
        .done(timer_done)
    );

    // ============================================================
    // Clock
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // Check state
    // ============================================================

    task check_state;
        input [2:0] expected;
        input [8*40-1:0] name;

        begin
            if (controller.current_state !== expected) begin

                $display("TEST FAILED: %s", name);
                $display("Expected state = %d", expected);
                $display("Actual state   = %d",
                         controller.current_state);

                errors = errors + 1;

            end
            else begin
                $display("TEST PASSED: %s", name);
            end
        end
    endtask

    // ============================================================
    // Check timer target
    // ============================================================

    task check_target;
        input [COUNTER_WIDTH-1:0] expected;
        input [8*40-1:0] name;

        begin
            if (timer_target !== expected) begin

                $display("TEST FAILED: %s", name);
                $display("Expected target = %d", expected);
                $display("Actual target   = %d", timer_target);

                errors = errors + 1;

            end
            else begin
                $display("TEST PASSED: %s", name);
            end
        end
    endtask

    // ============================================================
    // Main test
    // ============================================================

    initial begin

        clk       = 1'b0;
        rst       = 1'b1;
        ped_grant = 1'b0;
        errors    = 0;

        $display("");
        $display("==============================================");
        $display(" AMTGC CONTROLLER + TIMER INTEGRATION TEST");
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        check_state(
            NS_GREEN,
            "Reset -> NS_GREEN"
        );

        check_target(
            GREEN_TIME,
            "NS_GREEN target = GREEN_TIME"
        );

        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------

        rst = 1'b0;

        #1;

        // Initial timer should start
        if (timer_start !== 1'b1) begin
            $display("TEST FAILED: Initial timer start");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: Initial timer start");
        end

        // --------------------------------------------------------
        // Wait for real timer to complete NS_GREEN
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            NS_YELLOW,
            "Real timer: NS_GREEN -> NS_YELLOW"
        );

        check_target(
            YELLOW_TIME,
            "NS_YELLOW target = YELLOW_TIME"
        );

        // --------------------------------------------------------
        // Wait for real timer to complete NS_YELLOW
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            ALL_RED_1,
            "Real timer: NS_YELLOW -> ALL_RED_1"
        );

        check_target(
            RED_TIME,
            "ALL_RED_1 target = RED_TIME"
        );

        // --------------------------------------------------------
        // No pedestrian request
        // ALL_RED_1 -> EW_GREEN
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            EW_GREEN,
            "Real timer: ALL_RED_1 -> EW_GREEN"
        );

        check_target(
            GREEN_TIME,
            "EW_GREEN target = GREEN_TIME"
        );

        // --------------------------------------------------------
        // EW_GREEN -> EW_YELLOW
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            EW_YELLOW,
            "Real timer: EW_GREEN -> EW_YELLOW"
        );

        check_target(
            YELLOW_TIME,
            "EW_YELLOW target = YELLOW_TIME"
        );

        // --------------------------------------------------------
        // EW_YELLOW -> ALL_RED_2
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            ALL_RED_2,
            "Real timer: EW_YELLOW -> ALL_RED_2"
        );

        check_target(
            RED_TIME,
            "ALL_RED_2 target = RED_TIME"
        );

        // --------------------------------------------------------
        // ALL_RED_2 -> NS_GREEN
        // --------------------------------------------------------

        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            NS_GREEN,
            "Real timer: ALL_RED_2 -> NS_GREEN"
        );

        check_target(
            GREEN_TIME,
            "NS_GREEN restarted"
        );

        // --------------------------------------------------------
        // Pedestrian integration test
        // --------------------------------------------------------

        $display("");
        $display("Starting pedestrian integration test...");

        // Let current NS_GREEN finish
        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        // NS_YELLOW
        check_state(
            NS_YELLOW,
            "Pedestrian cycle: NS_GREEN -> NS_YELLOW"
        );

        // Finish yellow
        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        // ALL_RED_1
        check_state(
            ALL_RED_1,
            "Pedestrian cycle: -> ALL_RED_1"
        );

        // Request pedestrian service
        ped_grant = 1'b1;

        // Finish all-red
        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            PED_PHASE,
            "Pedestrian grant -> PED_PHASE"
        );

        check_target(
            PED_TIME,
            "PED_PHASE target = PED_TIME"
        );

        // Clear request
        ped_grant = 1'b0;

        // Finish pedestrian phase
        wait (timer_done == 1'b1);

        @(posedge clk);
        #1;

        check_state(
            EW_GREEN,
            "PED_PHASE -> EW_GREEN"
        );

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0) begin
            $display(" ALL INTEGRATION TESTS PASSED");
            $display(" Controller + Timer integration successful.");
        end
        else begin
            $display(" INTEGRATION TEST FAILED");
            $display(" Total errors = %d", errors);
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule