module junction_controller #(
    parameter COUNTER_WIDTH   = 8,
    parameter GREEN_TIME      = 10,
    parameter YELLOW_TIME     = 3,
    parameter RED_TIME        = 2,
    parameter PED_TIME        = 5,

    parameter MIN_GREEN_TIME  = 3,
    parameter MAX_GREEN_TIME  = 8,
    parameter GREEN_EXTENSION = 1
) (
    input wire                     clk,
    input wire                     rst,
    input wire                     enable,
    input wire                     timer_done,
    input wire                     ped_grant,
    input wire                     emergency_override,

    input wire [2:0]               traffic_density,

    output reg                     timer_start,
    output reg [COUNTER_WIDTH-1:0] timer_target,

    output reg [1:0]               ns_light,
    output reg [1:0]               ew_light
);

    // ============================================================
    // Light encodings
    // ============================================================

    localparam RED    = 2'b00;
    localparam YELLOW = 2'b01;
    localparam GREEN  = 2'b10;

    // ============================================================
    // FSM states
    // ============================================================

    localparam NS_GREEN  = 3'd0;
    localparam NS_YELLOW = 3'd1;
    localparam ALL_RED_1 = 3'd2;
    localparam PED_PHASE = 3'd3;
    localparam EW_GREEN  = 3'd4;
    localparam EW_YELLOW = 3'd5;
    localparam ALL_RED_2 = 3'd6;

    reg [2:0] current_state;
    reg [2:0] next_state;

    // Previous state is used to detect the beginning of
    // a new green phase.
    reg [2:0] previous_state;

    // Tracks whether the controller has completed initialization.
    reg initialized;

    // Tracks the previous enable value.
    // This is important for Junction B because it starts disabled
    // during the green-wave startup period.
    reg enable_previous;

    // ============================================================
    // Emergency
    // ============================================================

    reg emergency_active;

    // ============================================================
    // Adaptive timing
    // ============================================================

    // Density captured for the currently active green phase.
    reg [2:0] green_density;

    reg [COUNTER_WIDTH-1:0] calculated_green_time;

    // ============================================================
    // Calculate adaptive green time
    //
    // Green time =
    // MIN_GREEN_TIME + density * GREEN_EXTENSION
    //
    // capped at MAX_GREEN_TIME.
    // ============================================================

    always @(*) begin

        calculated_green_time =
            MIN_GREEN_TIME +
            (green_density * GREEN_EXTENSION);

        if (calculated_green_time > MAX_GREEN_TIME)
            calculated_green_time = MAX_GREEN_TIME;

    end

    // ============================================================
    // Emergency tracking
    // ============================================================

    always @(posedge clk) begin

        if (rst)
            emergency_active <= 1'b0;

        else if (emergency_override)
            emergency_active <= 1'b1;

        else
            emergency_active <= 1'b0;

    end

    // ============================================================
    // State register
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            current_state <= NS_GREEN;

        end

        else if (emergency_override) begin

            current_state <= ALL_RED_1;

        end

        else if (emergency_active) begin

            current_state <= NS_GREEN;

        end

        else if (!enable) begin

            current_state <= NS_GREEN;

        end

        else begin

            current_state <= next_state;

        end

    end

    // ============================================================
    // Previous state / enable tracking
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            previous_state  <= NS_GREEN;
            initialized     <= 1'b0;
            enable_previous <= 1'b0;

        end

        else begin

            previous_state  <= current_state;
            initialized     <= 1'b1;
            enable_previous <= enable;

        end

    end

    // ============================================================
    // Capture traffic density
    //
    // Density is sampled:
    //
    // 1. When the controller becomes enabled.
    // 2. When entering NS_GREEN.
    // 3. When entering EW_GREEN.
    //
    // The captured density remains fixed for the green phase.
    // ============================================================

    always @(posedge clk) begin

        if (rst) begin

            green_density <= 3'd0;

        end

        else if (enable &&
                 !emergency_active &&
                 !emergency_override) begin

            // Controller has just become enabled.
            // This handles Junction B after green-wave delay.

            if (!enable_previous) begin

                green_density <= traffic_density;

            end

            // New NS_GREEN phase

            else if ((current_state == NS_GREEN) &&
                     (previous_state != NS_GREEN)) begin

                green_density <= traffic_density;

            end

            // New EW_GREEN phase

            else if ((current_state == EW_GREEN) &&
                     (previous_state != EW_GREEN)) begin

                green_density <= traffic_density;

            end

        end

    end

    // ============================================================
    // Next-state logic
    // ============================================================

    always @(*) begin

        next_state = current_state;

        case (current_state)

            NS_GREEN: begin

                if (timer_done)
                    next_state = NS_YELLOW;

            end

            NS_YELLOW: begin

                if (timer_done)
                    next_state = ALL_RED_1;

            end

            ALL_RED_1: begin

                if (timer_done) begin

                    if (ped_grant)
                        next_state = PED_PHASE;
                    else
                        next_state = EW_GREEN;

                end

            end

            PED_PHASE: begin

                if (timer_done)
                    next_state = EW_GREEN;

            end

            EW_GREEN: begin

                if (timer_done)
                    next_state = EW_YELLOW;

            end

            EW_YELLOW: begin

                if (timer_done)
                    next_state = ALL_RED_2;

            end

            ALL_RED_2: begin

                if (timer_done)
                    next_state = NS_GREEN;

            end

            default: begin

                next_state = NS_GREEN;

            end

        endcase

    end

    // ============================================================
    // Moore output logic
    // ============================================================

    always @(*) begin

        ns_light = RED;
        ew_light = RED;

        if (!enable ||
            emergency_active ||
            emergency_override) begin

            ns_light = RED;
            ew_light = RED;

        end

        else begin

            case (current_state)

                NS_GREEN: begin

                    ns_light = GREEN;
                    ew_light = RED;

                end

                NS_YELLOW: begin

                    ns_light = YELLOW;
                    ew_light = RED;

                end

                ALL_RED_1: begin

                    ns_light = RED;
                    ew_light = RED;

                end

                PED_PHASE: begin

                    ns_light = RED;
                    ew_light = RED;

                end

                EW_GREEN: begin

                    ns_light = RED;
                    ew_light = GREEN;

                end

                EW_YELLOW: begin

                    ns_light = RED;
                    ew_light = YELLOW;

                end

                ALL_RED_2: begin

                    ns_light = RED;
                    ew_light = RED;

                end

                default: begin

                    ns_light = RED;
                    ew_light = RED;

                end

            endcase

        end

    end

    // ============================================================
    // Timer target
    // ============================================================

    always @(*) begin

        timer_target = RED_TIME;

        case (current_state)

            NS_GREEN: begin

                // If this is the first active cycle after enable,
                // use the current density immediately.
                //
                // This prevents Junction B from using its reset
                // density of zero after the green-wave delay.

                if (!enable_previous) begin

                    timer_target =
                        MIN_GREEN_TIME +
                        (traffic_density * GREEN_EXTENSION);

                    if (timer_target > MAX_GREEN_TIME)
                        timer_target = MAX_GREEN_TIME;

                end

                else begin

                    timer_target = calculated_green_time;

                end

            end

            NS_YELLOW: begin

                timer_target = YELLOW_TIME;

            end

            ALL_RED_1: begin

                timer_target = RED_TIME;

            end

            PED_PHASE: begin

                timer_target = PED_TIME;

            end

            EW_GREEN: begin

                // Same first-active-cycle handling for EW green.

                if (!enable_previous) begin

                    timer_target =
                        MIN_GREEN_TIME +
                        (traffic_density * GREEN_EXTENSION);

                    if (timer_target > MAX_GREEN_TIME)
                        timer_target = MAX_GREEN_TIME;

                end

                else begin

                    timer_target = calculated_green_time;

                end

            end

            EW_YELLOW: begin

                timer_target = YELLOW_TIME;

            end

            ALL_RED_2: begin

                timer_target = RED_TIME;

            end

            default: begin

                timer_target = RED_TIME;

            end

        endcase

        // Safety override

        if (!enable ||
            emergency_active ||
            emergency_override) begin

            timer_target = RED_TIME;

        end

    end

    // ============================================================
    // Timer start
    // ============================================================

    always @(*) begin

        timer_start = 1'b0;

        if (enable &&
            !emergency_active &&
            !emergency_override) begin

            // First activation

            if (!initialized) begin

                timer_start = 1'b1;

            end

            // State transition

            else if (current_state != previous_state) begin

                timer_start = 1'b1;

            end

            // Controller has just been enabled

            else if (!enable_previous) begin

                timer_start = 1'b1;

            end

        end

    end

endmodule
