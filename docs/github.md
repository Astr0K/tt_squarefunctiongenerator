# GitHub and Tiny Tapeout workflows

## Existing repository

```bash
git clone https://github.com/Astr0K/tt_squarefunctiongenerator.git
cd tt_squarefunctiongenerator
```

For a private repository, authenticate with your own GitHub account using your normal SSH or credential-manager setup. Never commit tokens or credentials.

After editing and testing:

```bash
git add .
git commit -m "Describe the change"
git push
```

## Creating another copy

Use the official [GF180 template](https://github.com/TinyTapeout/ttgf-verilog-template), or create an empty repository. Copy this project's contents into its root, including hidden configuration directories. `info.yaml`, `src/`, `test/`, and `.github/` must be at the repository root, not nested inside another project directory.

For an empty repository:

```bash
git init -b main
git add .
git commit -m "Initial GF180 reaction game project"
git remote add origin https://github.com/YOUR_USERNAME/tt_squarefunctiongenerator.git
git push -u origin main
```

## Workflows

- `test`: Icarus/cocotb RTL simulation.
- `docs`: Tiny Tapeout datasheet generation.
- `gds`: GF180 implementation, precheck, gate-level tests and viewer deployment.
- `fpga`: optional manual FPGA build; not required for ASIC fabrication.

Check the Actions tab for actual results. Workflow files alone do not establish a successful physical build. The viewer may require GitHub Pages to be enabled and a plan supporting Pages for the repository's visibility. Do not change repository visibility merely to enable a viewer without deciding whether the source should be public.

## Before shuttle submission

Confirm that `ttgf26c` is the correct workflow reference for your assigned GF180 shuttle. This reference came from the official template used to prepare the project. Check tile fit, timing, DRC/LVS, precheck and gate-level simulation. The 1x1 tile declaration is a requested allocation, not proof of physical fit.

The external operating clock is **10000 Hz**. The 20 ns physical-flow constraint does not configure the board clock. Verify your board revision, connector mapping and display wiring separately.

Uploading to GitHub is not submission to fabrication.
