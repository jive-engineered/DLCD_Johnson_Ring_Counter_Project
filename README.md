# N-Bit Johnson Ring Counter (Verilog HDL)

An RTL implementation and verification of a parameterized **Johnson Ring Counter** (also known as a **Twisted Ring Counter** or **Möbius Counter**) designed in Verilog HDL.

---

## 📌 Overview

A Johnson counter is a modified shift register where the inverted output ($\overline{Q}$) of the most significant bit (MSB) is fed back into the data input ($D$) of the least significant bit (LSB). 

While a standard $N$-bit ring counter cycles through only $N$ states, an $N$-bit Johnson counter yields **$2N$ distinct states**, making it twice as resource-efficient for sequence generation, frequency division, and multiphase clock distribution.

---

## ⚙️ Theory & State Transition

For a standard **4-bit Johnson Counter** ($N = 4$), the circuit transitions through $2 \times 4 = 8$ states before repeating:

### 4-Bit State Table

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

> **Note on Unused States:** A 4-bit register has $2^4 = 16$ possible combinations. The remaining 8 states (e.g., `0101`, `1010`) are **illegal/unused states**. In safety-critical designs, self-correcting logic is implemented to guide the counter back to an operational state if an illegal state occurs due to power-on glitches.

---

## 🧩 Module Structure

### Port List

| Port Name | Direction | Bit Width | Description                                 |
|:----------|:---------:|:---------:|:--------------------------------------------|
| `clk`     | Input     | 1         | System clock (positive-edge triggered)      |
| `rst_n`   | Input     | 1         | Asynchronous active-low reset               |
| `q_out`   | Output    | `WIDTH`   | Parallel counter output vector              |

### Module Hierarchy

```text
johnson_counter_repo/
├── rtl/
│   └── johnson_counter.v       # Parameterized RTL design
├── tb/
│   └── tb_johnson_counter.v    # Self-checking testbench
├── sim/
│   └── wave.vcd                # Value Change Dump for waveforms
├── docs/
│   └── schematic.png           # Circuit diagram
└── README.md                   # Project documentation
