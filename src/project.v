// Reaction game with synchronized, debounced controls. External clock: 10 kHz.
`default_nettype none
module tt_um_squarefunctiongenerator (
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);
    // Assert reset asynchronously; release only after 100 stable clock cycles.
    reg [1:0] reset_sync;
    reg [6:0] reset_count;
    reg ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reset_sync <= 2'b00;
            reset_count <= 7'd0;
            ready <= 1'b0;
        end else begin
            reset_sync <= {reset_sync[0], 1'b1};
            if (!reset_sync[1]) begin
                reset_count <= 7'd0;
                ready <= 1'b0;
            end else if (!ready) begin
                if (reset_count == 7'd99)
                    ready <= 1'b1;
                else
                    reset_count <= reset_count + 1'b1;
            end
        end
    end
    wire [4:0] controls;
    genvar i;
    generate for (i=0; i<5; i=i+1) begin : input_filters
        square_debounce filter (
            .clk(clk), .ready(ready), .raw(ui_in[i]), .clean(controls[i])
        );
    end endgenerate

    // 10000 / 1250 = 8 Hz enable, not a generated clock.
    reg [10:0] prescaler;
    wire tick_8hz = (prescaler == 11'd1249);
    always @(posedge clk) begin
        if (!ready)
            prescaler <= 11'd0;
        else if (tick_8hz)
            prescaler <= 11'd0;
        else
            prescaler <= prescaler + 1'b1;
    end
    reg [3:0] divider;
    reg [3:0] rng;
    reg selected_previous;
    reg armed;
    reg [3:0] countdown;
    reg cue, win, fail;
    reg selected;

    // MUX 4:1. All registers use clk, never the multiplexed signal.
    always @* begin
        case (controls[1:0])
            2'b00: selected = divider[3];
            2'b01: selected = divider[2];
            2'b10: selected = divider[1];
            default: selected = divider[0];
        endcase
    end
    wire rising = selected & ~selected_previous;
    wire falling = ~selected & selected_previous;
    wire round_reset = ~ready | controls[4] | ~controls[2];
    wire done = win | fail;
    wire rng_done = armed & (countdown == 4'd0);

    // Global reset only: these blocks keep running between rounds.
    always @(posedge clk) begin
        if (!ready) begin
            divider <= 4'd0;
            rng <= 4'd0;
            selected_previous <= 1'b0;
        end else begin
            if (tick_8hz) divider <= divider + 1'b1;
            rng <= {rng[2:0], ~(rng[3] ^ rng[2])};
            selected_previous <= selected;
        end
    end

    // Filtered start/restart act synchronously. Response is checked at 10 kHz.
    always @(posedge clk) begin
        if (round_reset) begin
            armed <= 1'b0;
            countdown <= 4'd0;
            cue <= 1'b0;
            win <= 1'b0;
            fail <= 1'b0;
        end else begin
            armed <= 1'b1;
            if (!armed)
                countdown <= {1'b1, rng[2:0]};
            else if (tick_8hz && countdown != 4'd0)
                countdown <= countdown - 1'b1;
            cue <= (rng_done & rising & ~done) |
                   (cue & ~falling & ~controls[3] & ~done);
            win <= win | (cue & controls[3] & ~done);
            fail <= fail | (~cue & controls[3] & ~done) |
                    (cue & ~controls[3] & falling & ~done);
        end
    end

    // Active-high segments: bit 0=a, ... bit 6=g, bit 7=DP.
    wire [6:0] level_segments;
    assign level_segments[0] = controls[1] ^ controls[0];
    assign level_segments[1] = 1'b1;
    assign level_segments[2] = ~controls[0] | controls[1];
    assign level_segments[3] = controls[1] ^ controls[0];
    assign level_segments[4] = ~controls[1] & controls[0];
    assign level_segments[5] = controls[1] & controls[0];
    assign level_segments[6] = controls[1] | controls[0];
    assign uo_out = {cue, done ? {fail, 2'b11, win, win, 2'b01}
                                    : level_segments};
    assign uio_out = 8'd0;
    assign uio_oe = 8'd0;
    wire _unused = &{1'b0, ena, ui_in[7:5], uio_in};
endmodule
// Require 100 consecutive samples different from the accepted level (10 ms).
// Both rising and falling transitions are filtered, after two synchronizer FFs.
module square_debounce (
    input wire clk,
    input wire ready,
    input wire raw,
    output reg clean
);
    reg [1:0] sync;
    reg [6:0] stable_count;
    always @(posedge clk) begin
        if (!ready) begin
            sync <= 2'b00;
            stable_count <= 7'd0;
            clean <= 1'b0;
        end else begin
            sync <= {sync[0], raw};
            if (sync[1] == clean)
                stable_count <= 7'd0;
            else if (stable_count == 7'd99) begin
                clean <= sync[1];
                stable_count <= 7'd0;
            end else
                stable_count <= stable_count + 1'b1;
        end
    end
endmodule
`default_nettype wire
