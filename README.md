# 4-Bit Ring and Johnson Counter (Verilog HDL)

An RTL implementation and verification of a **4-bit Ring Counter** and **Johnson Counter** (also known as a **Twisted Ring Counter** or **Möbius Counter**) in a single Verilog module, selectable at run time through a `mode` input.

---

## 📌 Overview

Both counters are built from a 4-bit shift register whose most significant bit (MSB) is fed back into the least significant bit (LSB):

- **Ring counter (`mode = 0`):** the MSB ($Q_3$) is fed back unchanged, so a single `1` circulates through the register.
- **Johnson counter (`mode = 1`):** the inverted MSB ($\overline{Q_3}$) is fed back, so the register fills with `1`s and then with `0`s.

While an $N$-bit ring counter cycles through only $N$ states, an $N$-bit Johnson counter yields **$2N$ distinct states** from the same number of flip-flops.

The design also provides:

- A **synchronous, active-high reset** that loads the start state of the selected mode.
- An **enable** input that advances the count when high and holds the current state when low.
- **Mode-change protection:** whenever `mode` changes, the counter automatically loads the start state of the new mode, so it can never continue from a state that is illegal in the new mode.

---

## ⚙️ Theory & State Transition

### Next-State Equations

For both modes, every bit takes the value of its lower neighbour at each enabled rising clock edge:

$$Q_3^{+} = Q_2, \quad Q_2^{+} = Q_1, \quad Q_1^{+} = Q_0$$

Only the LSB differs between the two modes:

| Mode | LSB Feedback | Verilog |
|:----:|:------------:|:--------|
| Ring (`mode = 0`) | $Q_0^{+} = Q_3$ | `q <= {q[2:0], q[3]};` |
| Johnson (`mode = 1`) | $Q_0^{+} = \overline{Q_3}$ | `q <= {q[2:0], ~q[3]};` |

### 4-Bit Ring Counter State Table (`mode = 0`)

The ring counter transitions through $N = 4$ states before repeating:

| Clock Cycle | Flip-Flop States ($Q_3 \, Q_2 \, Q_1 \, Q_0$) | State Name | Decimal Equivalent |
|:-----------:|:---------------------------------------------:|:----------:|:------------------:|
| **Reset**   | `0 0 0 1`                                     | $S_0$      | 1                  |
| **1**       | `0 0 1 0`                                     | $S_1$      | 2                  |
| **2**       | `0 1 0 0`                                     | $S_2$      | 4                  |
| **3**       | `1 0 0 0`                                     | $S_3$      | 8                  |
| **4**       | `0 0 0 1` (Repeats)                           | $S_0$      | 1                  |

### 4-Bit Johnson Counter State Table (`mode = 1`)

The Johnson counter transitions through $2 \times 4 = 8$ states before repeating:

| Clock Cycle | Flip-Flop States ($Q_3 \, Q_2 \, Q_1 \, Q_0$) | State Name | Decimal Equivalent |
|:-----------:|:---------------------------------------------:|:----------:|:------------------:|
| **Reset**   | `0 0 0 0`                                     | $S_0$      | 0                  |
| **1**       | `0 0 0 1`                                     | $S_1$      | 1                  |
| **2**       | `0 0 1 1`                                     | $S_2$      | 3                  |
| **3**       | `0 1 1 1`                                     | $S_3$      | 7                  |
| **4**       | `1 1 1 1`                                     | $S_4$      | 15                 |
| **5**       | `1 1 1 0`                                     | $S_5$      | 14                 |
| **6**       | `1 1 0 0`                                     | $S_6$      | 12                 |
| **7**       | `1 0 0 0`                                     | $S_7$      | 8                  |
| **8**       | `0 0 0 0` (Repeats)                           | $S_0$      | 0                  |

> **Note on Unused States:** A 4-bit register has $2^4 = 16$ possible combinations. The ring counter uses 4 of them (12 unused) and the Johnson counter uses 8 (8 unused, e.g. `0101`, `1010`). This design does **not** include self-correcting logic. Instead, it prevents illegal states by loading a valid start state on reset and whenever `mode` changes.

---

## 🧩 Module Structure

### Port List

| Port Name | Direction | Bit Width | Description                                                    |
|:----------|:---------:|:---------:|:---------------------------------------------------------------|
| `clk`     | Input     | 1         | System clock (positive-edge triggered)                         |
| `reset`   | Input     | 1         | Synchronous active-high reset                                  |
| `enable`  | Input     | 1         | `1` = advance the count, `0` = hold the current state          |
| `mode`    | Input     | 1         | `0` = Ring counter, `1` = Johnson counter                      |
| `q`       | Output    | 4         | Parallel counter output vector (`q[3]` = MSB, `q[0]` = LSB)    |

### Control Priority

At every rising edge of `clk`, the first matching condition decides the next state:

| Priority | Condition                                     | Action                                                 |
|:--------:|:----------------------------------------------|:-------------------------------------------------------|
| **1**    | `reset = 1`, or `mode` changed since the last edge | Load the start state: `0001` (Ring) or `0000` (Johnson) |
| **2**    | `enable = 1`                                  | Advance one step in the selected sequence              |
| **3**    | `enable = 0`                                  | Hold the current state                                 |

A mode change is detected by an internal register `mode_d`, which stores the value of `mode` from the previous clock edge and is compared with the current `mode`.

### Module Hierarchy

```text
DLCD_Johnson_Ring_Counter_Project/
├── src/
│   └── ring_johnson_counter.v      # RTL design (Ring + Johnson, mode select)
├── testbench/
│   └── tb_ring_johnson_counter.v   # Self-checking testbench (34 checks)
├── docs/
│   ├── design_notes.md             # Design and verification notes
│   └── expected_output.txt         # Reference simulation log (Icarus Verilog)
└── README.md                       # Project documentation
```

The waveform file `ring_johnson_counter.vcd` is generated when the simulation runs; it is not stored in the repository.

---

## 🧪 Verification

The testbench `tb_ring_johnson_counter.v` is **self-checking**: it compares `q` against the expected value at 34 points and prints `PASS` or `FAIL` for each.

| Test                                   | What It Verifies                                              |
|:---------------------------------------|:--------------------------------------------------------------|
| Ring reset and sequence                | Reset loads `0001`; two complete Ring cycles                  |
| Johnson reset and sequence             | Reset loads `0000`; two complete Johnson cycles               |
| Hold (both modes)                      | `enable = 0` keeps the current state                          |
| Mid-run reset (both modes)             | Reset during counting returns to the start state              |
| Mode switch without reset              | Johnson → Ring loads `0001`; Ring → Johnson loads `0000`      |

A successful run prints 34 `PASS` lines followed by `ALL TESTS PASSED`, matching `docs/expected_output.txt`. On the first mismatch, the testbench prints a `FAIL` line with the expected and actual values and stops the simulation with `$finish`.

---

## ▶️ Running the Simulation

Using [Icarus Verilog](https://github.com/steveicarus/iverilog) and [GTKWave](https://github.com/gtkwave/gtkwave):

```bash
iverilog -g2012 -o sim.out src/ring_johnson_counter.v testbench/tb_ring_johnson_counter.v
vvp sim.out
gtkwave ring_johnson_counter.vcd
```

The clock period is 10 ns (100 MHz) and the full test runs for 386 ns.
