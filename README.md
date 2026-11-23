# Square Function Generator & Reaction Game

A Verilog design for **Tiny Tapeout GF180**, combining a selectable square-wave divider, pseudo-random waiting time, and a reaction game with debounced controls.

- Top module: `tt_um_squarefunctiongenerator`
- External operating clock: **10 kHz**
- Input debounce: **10 ms**, on both transitions
- Technology: `gf180mcuD`
- Template workflow reference: `ttgf26c` (confirm compatibility with your target shuttle)

## Clock and difficulty

**Supply 10 kHz, not 8 Hz.** An internal divide-by-1250 counter generates an 8 Hz clock enable. A four-bit binary counter and 4:1 multiplexer select the reaction window. All registers use the same external clock; no multiplexed signal is used as a clock.

| UI1 | UI0 | Display | Internal waveform | Reaction window |
|---|---|---|---|---|
| 0 | 0 | 1 | 0.5 Hz | 1 s |
| 0 | 1 | 2 | 1 Hz | 500 ms |
| 1 | 0 | 3 | 2 Hz | 250 ms |
| 1 | 1 | 4 | 4 Hz | 125 ms |

The reaction window is the waveform's high half-period. The divided waveforms are internal: all eight dedicated outputs drive the display.

## Pin assignments

DIP numbers below follow the original Wokwi schematic. Check your physical board revision and routing before connecting hardware.

| Port | Function | Schematic control |
|---|---|---|
| `clk` | External 10 kHz clock | Clock generator |
| `rst_n` | Active-low global reset | RESET button |
| `ui_in[0]` | Difficulty LSB | DIP1 |
| `ui_in[1]` | Difficulty MSB | DIP2 |
| `ui_in[2]` | Run game; low holds the round in reset | DIP3 |
| `ui_in[3]` | Active-high player response | DIP4 |
| `ui_in[4]` | Active-high round restart | DIP5 |
| `ui_in[7:5]` | Unused | DIP6–8 |
| `uo_out[6:0]` | Active-high segments a through g | Display |
| `uo_out[7]` | Decimal point: reaction cue | DP |
| `uio_*` | Unused; output enables are low | — |
| `ena` | Standard TT infrastructure signal; not the game-start control | — |

## Playing

1. Select the design on your board and supply a 10 kHz clock.
2. Set UI2, UI3 and UI4 low. Assert and release the global reset while the clock runs.
3. Choose difficulty with UI1:UI0 and allow at least 20 ms for the controls to settle.
4. Raise UI2 and leave it high. Wait for the decimal point to light up.
5. Raise UI3 while the decimal point is on, and keep the response stable.
6. A successful response displays `0x3D`; an early or late response displays `F` (`0x71`). The result remains latched.
7. Lower UI3, then hold UI4 high for at least 20 ms and release it to start another round.

The success pattern intentionally preserves the original schematic: segments a, c, d, e and f (`0x3D`). It is not a standard U (`0x3E`).

## Debounce behavior

Each control passes through two synchronizer flip-flops followed by a filter requiring 100 consecutive samples of the new level. At 10 kHz this is 10 ms, plus synchronization and control latency. Both pressing and releasing are filtered.

The response is evaluated every 100 us after filtering. A response whose filter completes after the window closes loses; the filter delay is not compensated. A brief pulse can be intentionally rejected.

Global reset asserts asynchronously in its conditioner and resets the game on the next clock. Release requires synchronization and 100 stable cycles. Keep the clock running during reset.

## Repository contents

| Path | Purpose |
|---|---|
| `src/project.v` | Synthesizable RTL, synchronizers and debounce filters |
| `src/config.json` | Official GF180 physical-flow configuration |
| `info.yaml` | Tiny Tapeout metadata and pinout |
| `docs/info.md` | Tiny Tapeout datasheet |
| `docs/design.md` | Architecture and operating details |
| `docs/github.md` | GitHub setup and workflow instructions |
| `docs/verification.md` | Verification results and limitations |
| `test/` | Icarus/cocotb testbench |
| `.github/workflows/` | RTL tests, physical flow, documentation and optional FPGA build |

## Run the tests

On Ubuntu or Pop!_OS:

```bash
sudo apt update
sudo apt install iverilog make python3-venv
python3 -m venv .venv
source .venv/bin/activate
pip install -r test/requirements.txt
cd test
make
python -m cocotb_tools.check_results results.xml
```

Simulation uses accelerated 100 ns cycles while retaining the hardware cycle counts. Operating times assume a 10 kHz external clock. See [verification results](docs/verification.md).

## Implementation notes

- Set difficulty before starting. Each bit is filtered independently; changing both bits is not an atomic update.
- The four-bit LFSR is deterministic and repeats after 15 states. It is not a cryptographic random source.
- Round restart does not reset the free-running divider or LFSR; global reset does.
- This revision adds filtering, a prescaler and faster response sampling to the original Wokwi logic. It is not cycle-equivalent to the original 8 Hz JSON.
- Synchronizers reduce metastability risk; placement and timing must still be reviewed in the physical flow.
- The template's `CLOCK_PERIOD=20` ns is an implementation constraint, not the game's operating clock. `info.yaml` declares 10000 Hz.
- GDS, precheck, DRC/LVS and board validation remain separate from the completed RTL tests. Confirm the target shuttle and tile fit before submission.

See [GitHub instructions](docs/github.md). The original template is [TinyTapeout/ttgf-verilog-template](https://github.com/TinyTapeout/ttgf-verilog-template).
