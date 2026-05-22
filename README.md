# 16-Stage Pipelined DES Hardware Accelerator with First-Order Boolean Masking for SCA Resilience

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Verilog](https://img.shields.io/badge/Language-Verilog%202012-blue.svg)](https://en.wikipedia.org/wiki/Verilog)

This project implements a high-performance, 16-stage pipelined DES (Data Encryption Standard) hardware accelerator featuring **First-Order Boolean Masking** and a **64-bit LFSR-based dynamic re-masking system** to defend against Side-Channel Attacks (SCA), such as Differential Power Analysis (DPA).

---

## Deep Architectural Analysis

### 1. High-Throughput 16-Stage Pipeline
Unlike iterative DES implementations that reuse a single round module, this design fully unfolds the 16 rounds into a linear pipeline.
*   **Performance**: Achieves a throughput of **one 64-bit ciphertext per clock cycle** after the initial 16-cycle latency.
*   **Per-Data Keying**: The key schedule is fully pipelined. Each 64-bit plaintext entering the pipeline can be associated with a **unique 64-bit key**. This allows for high-speed encryption/decryption of multiple independent streams or frequent key rotations without any pipeline stalls.
*   **Critical Path**: By inserting registers between each round, the critical path is limited to a single Feistel function and a few XOR gates, allowing for high $F_{max}$.
*   **Synchronicity**: The key schedule and data path are perfectly aligned, ensuring that subkeys are available exactly when the corresponding data chunk reaches a pipeline stage.

### 2. First-Order Boolean Masking Theory
The core security feature is the decoupling of intermediate data from physical power consumption.
*   **Masking Equation**: Every data bit $x$ is represented as a pair $(x_m, m)$ such that $x = x_m \oplus m$.
*   **Linear Operations**: Operations like IP, IP_INV, Expansion (E), and Permutation (P) are linear with respect to XOR. Thus, $E(x \oplus m) = E(x) \oplus E(m)$. The mask $m$ is simply transformed by the same function.
*   **Non-Linear Operations (S-Boxes)**: This is where SCA leakage is most critical. We use **Masked S-Boxes** that take $(x \oplus m_{in})$ and $m_{in}$ as inputs and produce $(S(x) \oplus m_{out})$ using $m_{out}$ as a re-masking value.

### 3. Dynamic Re-Masking via 64-bit LFSR
The system incorporates a **64-bit Linear Feedback Shift Register (LFSR)** (often referred to as a "Pseudo-Random Number Generator") to provide entropy for the masking logic.
*   **Initial Masking**: The user-provided `mask_in` is XORed with the LFSR's 64-bit output to create a **spatially and temporally dynamic initial mask**.
*   **Round-Level Re-masking**: Each round's S-Box output is protected by a fresh 32-bit `rnd_mask` sliced from the LFSR. This ensures that even if an attacker attempts to correlate power traces across rounds, the masks are constantly changing, breaking the first-order correlation.
*   **LFSR Polynomial**: $x^{64} + x^{63} + x^{61} + x^{60} + 1$. This primitive polynomial ensures a maximum period of $2^{64}-1$.

### 4. ROM-Less Combinational S-Boxes
Traditional S-Boxes using ROM/LUT tables can leak information through timing or power "glitches" during lookup.
*   **Boolean Equation Logic**: All 8 S-Boxes are implemented as pure combinational boolean clouds.
*   **Gate-Level Absorption**: During synthesis, the unmasking ($x_m \oplus m_{in}$) and re-masking ($S(x) \oplus m_{out}$) are optimized into the same physical LUTs. This prevents the "true value" $x$ from ever appearing as a stable signal on any internal wire.

---

## Project Structure

| File | Role |
| :--- | :--- |
| `src/des_top.v` | Top-level module, integrates LFSR, IP/IP_INV, and the 16-stage pipeline. |
| `src/des_round.v` | A single registered pipeline stage. |
| `src/feistel.v` | Masked Feistel function with E-box, S-box, and P-box logic. |
| `src/lfsr.v` | 64-bit PRNG providing entropy for masking. |
| `src/sbox*.v` | Combinational masked S-Box implementations (1-8). |
| `src/des_defines.vh` | Permutation matrices and constant definitions. |
| `Docs/Architecture.md` | Detailed data flow and mask propagation diagram. |

---

## Simulation & Verification

The project uses NIST standard Known Answer Test (KAT) vectors for verification.

### Requirements
*   **Icarus Verilog** (iverilog)
*   **GTKWave** (for waveform viewing)

### Running Simulation

```powershell
# Windows (PowerShell)
.\run_sim.ps1
```

```bash
# Linux/Manual
iverilog -g2012 -I src -s tb_des -o des_sim_v src/*.v
vvp des_sim_v
```

### Waveform Analysis
In `dump.vcd`, you can observe:
1.  `plaintext` being XORed with a changing `dynamic_mask`.
2.  `masked_plaintext` flowing through 16 stages of `des_round_stage`.
3.  `ciphertext` emerging 16 cycles later, correctly decrypted/unmasked.

---

## Security Recommendations for Implementation

1.  **True Randomness**: In a production ASIC/FPGA, replace or seed the LFSR with a **True Random Number Generator (TRNG)**.
2.  **Synthesis Constraints**: Use `DONT_TOUCH` or `KEEP_HIERARCHY` on S-Box modules to prevent the synthesizer from "optimizing away" the masking logic (e.g., merging $x_m \oplus m$ back into $x$).
3.  **Glitch Protection**: For higher security, consider adding "Dual-Rail with Pre-charge" or "Masked Gates with Glitch Filtering" if targeting high-order SCA resilience.

---

## License
This project is licensed under the MIT License - see the LICENSE file for details.
