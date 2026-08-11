`timescale 1ns/1ps

module junction_adaptive_tb;

    parameter COUNTER_WIDTH = 8;

    parameter MIN_GREEN_TIME  = 3;
    parameter MAX_GREEN_TIME  = 8;
    parameter GREEN_EXTENSION = 1;

    parameter YELLOW_TIME = 2;
    parameter RED_TIME    = 1;
    parameter PED_TIME    = 2;

    reg clk;
    reg rst;
    reg enable;
    reg timer_done;
    reg ped_grant;
    reg emergency_override;

    reg [2:0] traffic_density;

    wire timer_start;
    wire [COUNTER_WIDTH-1:0] timer_target;

    wire [1:0] ns_light;
    wire [1:0] ew_light;

    integer errors;
    integer expected_target;
    integer density;

    localparam RED    = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN  = 2'b10;

    // ============================================================
    // DUT
    // ============================================================

    junction_controller #(
        .COUNTER_WIDTH(COUNTER_WIDTH),

        .GREEN_TIME(10),
        .YELLOW_TIME(YELLOW_TIME),
        .RED_TIME(RED_TIME),
        .PED_TIME(PED_TIME),

        .MIN_GREEN_TIME(MIN_GREEN_TIME),
        .MAX_GREEN_TIME(MAX_GREEN_TIME),
        .GREEN_EXTENSION(GREEN_EXTENSION)
    ) dut (
        .clk                (clk),
        .rst                (rst),
        .enable             (enable),
        .timer_done         (timer_done),
        .ped_grant          (ped_grant),
        .emergency_override (emergency_override),
        .traffic_density    (traffic_density),

        .timer_start        (timer_start),
        .timer_target       (timer_target),

        .ns_light           (ns_light),
        .ew_light           (ew_light)
    );

    // ============================================================
    // Clock
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // Main test
    // ============================================================

    initial begin

        clk = 1'b0;

        rst = 1'b1;
        enable = 1'b1;
        timer_done = 1'b0;
        ped_grant = 1'b0;
        emergency_override = 1'b0;
        traffic_density = 3'd0;

        errors = 0;

        $display("");
        $display("==============================================");
        $display(" AMTGC TASK 4 ADAPTIVE TIMING TESTBENCH");
        $display("==============================================");
        $display("");

        // ========================================================
        // Reset test
        // ========================================================

        repeat (2)
            @(posedge clk);

        #1;

        if ((ns_light === GREEN) &&
            (ew_light === RED)) begin

            $display("TEST PASSED: Reset -> NS_GREEN");

        end
        else begin

            $display("TEST FAILED: Reset state");

            errors = errors + 1;

        end

        // ========================================================
        // Density sweep
        //
        // Each density gets a fresh reset so that the controller
        // always begins at NS_GREEN.
        // ========================================================

        for (density = 0; density < 8; density = density + 1) begin

            // Apply density while reset is active

            traffic_density = density[2:0];

            rst = 1'b1;

            repeat (2)
                @(posedge clk);

            #1;

            // Release reset

            rst = 1'b0;

            @(posedge clk);
            #1;

            // Calculate expected adaptive green time

            expected_target =
                MIN_GREEN_TIME +
                (density * GREEN_EXTENSION);

            if (expected_target > MAX_GREEN_TIME)
                expected_target = MAX_GREEN_TIME;

            // Verify we are actually in NS_GREEN

            if ((ns_light !== GREEN) ||
                (ew_light !== RED)) begin

                $display(
                    "TEST FAILED: Density %0d -> not in NS_GREEN",
                    density
                );

                errors = errors + 1;

            end
            else begin

                // Verify dynamic timer target

                if (timer_target == expected_target) begin

                    $display(
                        "TEST PASSED: Density %0d -> Green target = %0d",
                        density,
                        timer_target
                    );

                end
                else begin

                    $display(
                        "TEST FAILED: Density %0d -> Expected %0d, Got %0d",
                        density,
                        expected_target,
                        timer_target
                    );

                    errors = errors + 1;

                end

            end

        end

        // ========================================================
        // Test minimum green limit
        // ========================================================

        rst = 1'b1;
        traffic_density = 3'd0;

        repeat (2)
            @(posedge clk);

        rst = 1'b0;

        @(posedge clk);
        #1;

        if (timer_target >= MIN_GREEN_TIME) begin

            $display(
                "TEST PASSED: Minimum green limit = %0d",
                timer_target
            );

        end
        else begin

            $display("TEST FAILED: Minimum green limit");

            errors = errors + 1;

        end

        // ========================================================
        // Test maximum green limit
        // ========================================================

        rst = 1'b1;
        traffic_density = 3'd7;

        repeat (2)
            @(posedge clk);

        rst = 1'b0;

        @(posedge clk);
        #1;

        if (timer_target <= MAX_GREEN_TIME) begin

            $display(
                "TEST PASSED: Maximum green limit = %0d",
                timer_target
            );

        end
        else begin

            $display("TEST FAILED: Maximum green limit");

            errors = errors + 1;

        end

        // ========================================================
        // Test density sampling / holding
        //
        // Start with density 2.
        // Expected green target = 5.
        //
        // Change density to 7 while green is active.
        // Target must remain 5.
        // ========================================================

        rst = 1'b1;
        traffic_density = 3'd2;

        repeat (2)
            @(posedge clk);

        rst = 1'b0;

        @(posedge clk);
        #1;

        expected_target =
            MIN_GREEN_TIME +
            (2 * GREEN_EXTENSION);

        if (expected_target > MAX_GREEN_TIME)
            expected_target = MAX_GREEN_TIME;

        if (timer_target == expected_target) begin

            traffic_density = 3'd7;

            @(posedge clk);
            #1;

            if (timer_target == expected_target) begin

                $display(
                    "TEST PASSED: Density held during active green"
                );

            end
            else begin

                $display(
                    "TEST FAILED: Density changed active green target"
                );

                errors = errors + 1;

            end

        end
        else begin

            $display(
                "TEST FAILED: Could not establish density sample"
            );

            errors = errors + 1;

        end

        // ========================================================
        // Final result
        // ========================================================

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display(" ALL ADAPTIVE TIMING TESTS PASSED");
            $display(" Traffic-density timing verified.");

        end
        else begin

            $display(" ADAPTIVE TIMING TEST FAILED");
            $display(" Total errors = %0d", errors);

        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule