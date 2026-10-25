# Design notes

## Ring counter
A 4-bit ring counter circulates a single `1`. It is initialized to `0001`. At each enabled rising clock edge, the bits shift left and the old most-significant bit wraps around to the least-significant bit:

`q_next = {q[2:0], q[3]}`

Sequence: `0001 → 0010 → 0100 → 1000 → 0001`.

## Johnson counter
A 4-bit Johnson counter feeds the inverted most-significant bit back to the least-significant position:

`q_next = {q[2:0], ~q[3]}`

Sequence: `0000 → 0001 → 0011 → 0111 → 1111 → 1110 → 1100 → 1000 → 0000`.

## Control logic
- Synchronous active-high `reset` sets the state at the next rising edge.
- `enable=1` advances the selected sequence.
- `enable=0` holds the current state.
- `mode=0` selects Ring; `mode=1` selects Johnson.
- A change of `mode` (detected by comparing with the previous clock's `mode`) also loads the new mode's start state, so no manual reset is needed and illegal states are avoided.

## What the testbench verifies
1. Ring reset state and two complete Ring cycles.
2. Johnson reset state and two complete Johnson cycles.
3. State hold when `enable=0` in each mode.
4. Mid-run reset in both modes, and mode switching (Johnson->Ring, Ring->Johnson) without reset.
5. It dumps a waveform (`ring_johnson_counter.vcd`).
6. It terminates with `$fatal` if a checked state is incorrect.
