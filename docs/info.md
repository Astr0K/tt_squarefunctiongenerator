## How it works

GF180 reaction game with a 10 kHz external clock. UI0–UI4 each pass through a two-flop synchronizer and a 100-consecutive-sample debounce filter (10 ms for either transition). The reset conditioner asynchronously asserts and requires synchronized stable release for 100 cycles; game registers reset synchronously, so the clock must keep running.

An internal divide-by-1250 enable drives the original 4-bit frequency divider at 8 Hz. UI1:UI0 select /16, /8, /4 or /2, giving reaction windows of 1 s, 500 ms, 250 ms or 125 ms. All registers use the common 10 kHz clock. Response detection runs at 10 kHz after filtering. A response accepted after the window closes loses; the filter delay is not compensated.

A 4-bit XNOR LFSR runs at 10 kHz. A round captures a wait count of 8–15, decremented at 8 Hz, then waits for the selected rising edge. UI2 enables the round, UI3 is the response and UI4 resets the round. Outputs 0–6 drive active-high segments a–g; output 7 is the DP cue. Success shows the original pattern 0x3D; failure shows F (0x71). Unused bidirectional outputs are disabled.

## How to test

Supply 10 kHz, not the previous version's 8 Hz. Set UI2–UI4 low, assert then release reset. Choose difficulty and allow at least 20 ms for controls to settle. Raise UI2; when DP lights, raise UI3 and keep it stable. Lower UI3 before retrying, then hold UI4 high for at least 20 ms and release it. Keep difficulty fixed throughout a round.

Run make in test/ with Icarus and the supplied cocotb requirements. Tests cover all window widths, success, timeout, early response, rejected bounce pulses, stable transitions, restart and reset release. Physical GF180 flow and board validation remain pending.

## External hardware

A 10 kHz external clock and controls for UI0–UI4. Use the intended Tiny Tapeout board display or a compatible common-cathode display with appropriate current limiting/drivers. Confirm the board revision and electrical/pin mapping. The original 8 Hz Wokwi JSON is a reference for the earlier circuit, not a simulation of this revised RTL.
