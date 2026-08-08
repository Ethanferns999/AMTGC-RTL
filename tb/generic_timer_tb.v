module generic_timer_tb #(
    parameter COUNTER_WIDTH = 4
);

    reg                     clk;
    reg                     rst;
    reg                     start;
    reg [COUNTER_WIDTH-1:0] count_target;
    wire                    done;

    generic_timer #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .count_target(count_target),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        count_target = '0;

        // Reset test
        repeat (2) @(posedge clk);

        rst = 1'b0;

        @(posedge clk);
        #1;

        if (done !== 1'b0)
            $display("TEST FAILED: Reset test");
        else
            $display("TEST PASSED: Reset test");


        // Test 2: Normal counting
        count_target = 4'd5;
        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Counting cycles 2, 3 and 4
        repeat (3) begin
            @(posedge clk);
            #1;
        end

        // Counting cycle 5
        @(posedge clk);
        #1;

        if (done !== 1'b1)
            $display("TEST FAILED: Normal counting - done not asserted");
        else
            $display("TEST PASSED: Normal counting");

        // Test 3: DONE pulse width
        @(posedge clk);
        #1;

        if (done !== 1'b0)
            $display("TEST FAILED: DONE pulse width");
        else
            $display("TEST PASSED: DONE pulse width");
        // Test 4: Zero target
        count_target = '0;
        start = 1'b1;

        @(posedge clk);
        #1;

        if (done !== 1'b1)
            $display("TEST FAILED: Zero target");
        else
            $display("TEST PASSED: Zero target");

        start = 1'b0;

        // Verify DONE returns low
        @(posedge clk);
        #1;

        if (done !== 1'b0)
            $display("TEST FAILED: Zero target DONE pulse width");
        else
            $display("TEST PASSED: Zero target DONE pulse width");
        // Test 5: Reset while counting
        count_target = 8;
        start = 1'b1;

        // Start timer
        @(posedge clk);
        #1;

        start = 1'b0;

        // Allow timer to count
        repeat (2) begin
            @(posedge clk);
            #1;
        end

        // Assert synchronous reset
        rst = 1'b1;

        @(posedge clk);
        #1;

        if (dut.counter !== '0)
            $display("TEST FAILED: Reset during counting - counter");

        else if (dut.active !== 1'b0)
            $display("TEST FAILED: Reset during counting - active");

        else if (done !== 1'b0)
            $display("TEST FAILED: Reset during counting - done");

        else
            $display("TEST PASSED: Reset during counting");

        rst = 1'b0;
        // Test 6: Restart after completion
        rst = 1'b0;
        count_target = 3;
        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Remaining counting cycles
        repeat (2) begin
            @(posedge clk);
            #1;
        end

        if (done !== 1'b1)
            $display("TEST FAILED: First timer operation");

        else begin
            $display("First timer operation completed");

            // Start second operation
            count_target = 5;
            start = 1'b1;

            @(posedge clk);
            #1;

            start = 1'b0;

            repeat (3) begin
                @(posedge clk);
                #1;
            end

            @(posedge clk);
            #1;

            if (done !== 1'b1)
                $display("TEST FAILED: Timer restart");

            else
                $display("TEST PASSED: Timer restart");
        end
        $finish;

    end

endmodule