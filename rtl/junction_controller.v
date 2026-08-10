module junction_controller #(
    parameter COUNTER_WIDTH = 8,
    parameter GREEN_TIME    = 10,
    parameter YELLOW_TIME   = 3,
    parameter RED_TIME      = 2,
    parameter PED_TIME      = 5
) (
    input wire                      clk,
    input wire                      rst,
    input wire                      enable,
    input wire                      timer_done,
    input wire                      ped_grant,
    input wire                      emergency_override,

    output reg                      timer_start,
    output reg [COUNTER_WIDTH-1:0]  timer_target,
    output reg [1:0]                 ns_light,
    output reg [1:0]                 ew_light
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

    reg [2:0] previous_state;
    reg       initialized;
    reg       emergency_active;
reg enable_previous;

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
            // Resume safely from NS_GREEN after emergency
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
    // Previous-state tracking
    // ============================================================

 always @(posedge clk) begin

    if (rst) begin
        previous_state <= NS_GREEN;
        initialized    <= 1'b0;
        enable_previous <= 1'b0;
    end

    else begin
        previous_state <= current_state;
        initialized    <= 1'b1;
        enable_previous <= enable;
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

            NS_GREEN:
                timer_target = GREEN_TIME;

            NS_YELLOW:
                timer_target = YELLOW_TIME;

            ALL_RED_1:
                timer_target = RED_TIME;

            PED_PHASE:
                timer_target = PED_TIME;

            EW_GREEN:
                timer_target = GREEN_TIME;

            EW_YELLOW:
                timer_target = YELLOW_TIME;

            ALL_RED_2:
                timer_target = RED_TIME;

            default:
                timer_target = RED_TIME;

        endcase

        if (!enable ||
            emergency_active ||
            emergency_override)

            timer_target = RED_TIME;

    end

    // ============================================================
    // Timer start
    // ============================================================

  always @(*) begin

    timer_start = 1'b0;

    if (enable &&
        !emergency_active &&
        !emergency_override) begin

        if (!initialized)
            timer_start = 1'b1;

        else if (current_state != previous_state)
            timer_start = 1'b1;

        else if (!enable_previous)
            timer_start = 1'b1;

    end

end

endmodule
