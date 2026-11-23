# Verification

RTL simulator: Icarus Verilog 12.0. Test framework: cocotb 2.0.1.

The debounce revision passed **3 tests, with 0 failures** before publication:

| Test | Coverage |
|---|---|
| `windows_and_results` | Exact 10000/5000/2500/1250-cycle windows, timeout, retained result, restart and success at all levels |
| `bounce_and_early_response` | Rising/falling bounce, rejected short response pulses, sustained early response, in-window bounce, restart glitches and filtered disable |
| `reset_release_filter` | Repeated low reset pulses prevent release until a stable interval completes |

The simulation uses accelerated 100 ns cycles; hardware timing assumes a 10 kHz input. These functional tests replace comparison against the original 8 Hz circuit because debounce changes its temporal behavior.

This is not formal equivalence or physical validation. GDS generation, precheck, DRC/LVS, gate-level and board tests must be checked separately in the selected GF180 flow. Consult GitHub Actions for any later runs.
