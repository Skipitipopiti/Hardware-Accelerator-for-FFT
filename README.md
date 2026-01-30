# Hardware Accelerator for FFT (Radix-2 DIF)

This project features the design and implementation in **VHDL-2008** of a hardware accelerator for a 16-point **Fast Fourier Transform (FFT)**, based on the Cooley-Tukey **Decimation in Frequency (DIF)** algorithm.

The core of the system is a highly optimized **Butterfly** unit, capable of operating in "Continuous Mode" through data interleaving to maximize throughput.

## 🚀 Key Features

* **Butterfly Architecture**:
    * Internal pipeline for multipliers and adders.
    * **Single Mode**: Latency of 13 $t_{ck}$, throughput of 1 data / 13 $t_{ck}$.
    * **Continuous Mode**: Optimized throughput of **1 data / 6 $t_{ck}$** using interleaving.
* **Data Management**:
    * Fixed-point format: **24-bit** (signed fractional).
    * Rounding Strategy: **Round to Nearest Even** via a ROM Rounder (768 bits).
    * Dynamic Scaling: 2-bit scaling in the first stage and 1-bit in subsequent stages to prevent overflow.
* **Advanced Control**: 
    * Control Unit implemented as both a behavioral FSM and a Microprogrammed logic (Sequencer + Command Generator).

---

## 🛠 Repository Structure

* `/src`: VHDL source files.
    * `operators.vhd`: Adder, subtractor, multiplier, and ROM Rounder.
    * `butterfly.vhd`: Integration of the Butterfly Datapath and Control Unit.
    * `fft.vhd`: 16-point FFT Top-level with twiddle factor management.
    * `pkg_fft.vhd`: Utility functions (bit-reversal shuffle, twiddle calculation).
* `/tb`: Testbenches for individual modules and the full FFT system.
* `/scripts`: Python scripts for test vector generation and precision verification.

---

## 📊 Technical Details

### Datapath
The design is constrained to limited resources to optimize area:
* 1 Reconfigurable Multiplier (2 pipeline stages).
* 1 Adder + 1 Subtractor (1 pipeline stage each).
* Hybrid storage (Register File + local registers) to minimize global bus congestion.

### Precision and Rounding
The error is kept below **0.125 LSB** per Butterfly unit thanks to the ROM Rounder. It processes $n=3$ "integer" bits and $m=5$ "fractional" bits to perform high-precision rounding with minimal area overhead.

---

## 🧪 Testing and Simulation

### Requirements
* VHDL simulator compatible with **VHDL-2008** (e.g., ModelSim, QuestaSim, GHDL).
* Python 3.x (for test vector generation).

### Test Procedure
1.  **Vector Generation**:
    Run the Python script to obtain expected values:
    ```bash
    python scripts/test_gen.py
    ```
2.  **Butterfly Simulation**:
    Compile the `/src` files and run the `tb_butterfly` testbench. Verify the `done` signal assertion and the validity of $A'$ and $B'$ outputs.
3.  **FFT Simulation**:
    Run the `tb_fft` testbench. The system processes input vectors (e.g., impulses, constants, sinusoids) and produces the transformed output scaled by a factor of 32.

---

## 👥 Authors
* **Alessandro Crisafi** - s354852
* **Leonardo Donvito** - s347962
* **Marco Spataro** - s354698

*Project "Operation San Silvestro" - December 31, 2025*
