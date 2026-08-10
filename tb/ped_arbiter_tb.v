`timescale 1ns/1ps

module ped_arbiter_tb;

    reg clk;
    reg rst;

    reg req_a;
    reg req_b;

    wire grant_a;
    wire grant_b;

    integer errors;
    integer i;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------

    ped_arbiter dut (
        .clk(clk),
        .rst(rst),
        .req_a(req_a),
        .req_b(req_b),
        .grant_a(grant_a),
        .grant_b(grant_b)
    );

    // ------------------------------------------------------------
    // Clock
    // ------------------------------------------------------------

    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------

    initial begin

        clk    = 1'b0;
        rst    = 1'b1;
        req_a  = 1'b0;
        req_b  = 1'b0;
        errors = 0;

        $display("");
        $display("==============================================");
        $display(" AMTGC PEDESTRIAN ARBITER TESTBENCH");
        $display("==============================================");
        $display("");

        // --------------------------------------------------------
        // TEST 1: Reset
        // --------------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        if ((grant_a !== 1'b0) || (grant_b !== 1'b0)) begin
            $display("TEST FAILED: Reset grants");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: Reset grants");
        end

        rst = 1'b0;

        // --------------------------------------------------------
        // TEST 2: No requests
        // --------------------------------------------------------

        req_a = 1'b0;
        req_b = 1'b0;

        #1;

        if ((grant_a !== 1'b0) || (grant_b !== 1'b0)) begin
            $display("TEST FAILED: No requests -> no grants");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: No requests -> no grants");
        end

        // --------------------------------------------------------
        // TEST 3: Only A requests
        // --------------------------------------------------------

        req_a = 1'b1;
        req_b = 1'b0;

        #1;

        if ((grant_a !== 1'b1) || (grant_b !== 1'b0)) begin
            $display("TEST FAILED: A-only request");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: A-only request -> A granted");
        end

        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // TEST 4: Only B requests
        // --------------------------------------------------------

        req_a = 1'b0;
        req_b = 1'b1;

        #1;

        if ((grant_a !== 1'b0) || (grant_b !== 1'b1)) begin
            $display("TEST FAILED: B-only request");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: B-only request -> B granted");
        end

        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // TEST 5: Simultaneous requests
        // First simultaneous request should go to A
        // because reset initialized last_grant to B.
        // --------------------------------------------------------

        req_a = 1'b1;
        req_b = 1'b1;

        #1;

        if ((grant_a !== 1'b1) || (grant_b !== 1'b0)) begin
            $display("TEST FAILED: First simultaneous request");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: First simultaneous request -> A");
        end

        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // TEST 6: Second simultaneous request must go to B
        // --------------------------------------------------------

        #1;

        if ((grant_a !== 1'b0) || (grant_b !== 1'b1)) begin
            $display("TEST FAILED: Second simultaneous request");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: Second simultaneous request -> B");
        end

        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // TEST 7: Repeated simultaneous requests
        // Expected: A, B, A, B, A, B
        // --------------------------------------------------------

        for (i = 0; i < 6; i = i + 1) begin

            #1;

            if ((i % 2) == 0) begin

                if ((grant_a !== 1'b1) ||
                    (grant_b !== 1'b0)) begin

                    $display(
                        "TEST FAILED: Round-robin iteration %d expected A",
                        i
                    );

                    errors = errors + 1;

                end
                else begin

                    $display(
                        "TEST PASSED: Round-robin iteration %d -> A",
                        i
                    );

                end

            end

            else begin

                if ((grant_a !== 1'b0) ||
                    (grant_b !== 1'b1)) begin

                    $display(
                        "TEST FAILED: Round-robin iteration %d expected B",
                        i
                    );

                    errors = errors + 1;

                end
                else begin

                    $display(
                        "TEST PASSED: Round-robin iteration %d -> B",
                        i
                    );

                end

            end

            @(posedge clk);
            #1;

        end

        // --------------------------------------------------------
        // TEST 8: Mutual exclusion
        // --------------------------------------------------------

        req_a = 1'b1;
        req_b = 1'b1;

        #1;

        if ((grant_a == 1'b1) && (grant_b == 1'b1)) begin
            $display("TEST FAILED: Both grants active");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: Grants are mutually exclusive");
        end

        // --------------------------------------------------------
        // TEST 9: Request withdrawal
        // --------------------------------------------------------

        req_a = 1'b0;
        req_b = 1'b0;

        #1;

        if ((grant_a !== 1'b0) || (grant_b !== 1'b0)) begin
            $display("TEST FAILED: Grants remain active after requests removed");
            errors = errors + 1;
        end
        else begin
            $display("TEST PASSED: Grants clear when requests removed");
        end

        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("==============================================");

        if (errors == 0) begin
            $display(" ALL PEDESTRIAN ARBITER TESTS PASSED");
            $display(" Round-robin fairness verified.");
        end
        else begin
            $display(" PEDESTRIAN ARBITER TEST FAILED");
            $display(" Total errors = %d", errors);
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
