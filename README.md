# AXI4-Lite GPIO + PWM Peripheral

A fully synthesizable AXI4-Lite peripheral implemented in SystemVerilog, exposing GPIO output control, GPIO input sampling, and a runtime-configurable PWM generator through a memory-mapped register interface.

Designed and verified as part of an ASIC/Digital Design portfolio project. Simulated in Vivado behavioral simulation and synthesized through Vivado synthesis (no timing constraints applied; synthesis-clean with no errors or critical warnings).

---

## Architecture

The design is split into four sub-blocks instantiated under a single top-level module.

**AXI4-Lite Slave Interface (`axi4_slave.sv`)**

Implements the full AXI4-Lite write and read paths:

- Write address (AW), write data (W), and write response (B) channels
- Read address (AR) and read data (R) channels
- AW and W channels can arrive in any order — whichever arrives first is latched until the other is ready, then both are consumed together
- B-channel back-pressure: `AWREADY`/`WREADY` are deasserted while a `BVALID` response is pending
- `WSTRB` byte-lane masking passed through to the register file
- `SLVERR` response on unmapped write addresses and read-only register writes
- `SLVERR` response on unmapped read addresses; `RDATA` returns `0xDEADBEEF` as a debug sentinel

**Register File (`regfile.sv`)**

Four 32-bit memory-mapped registers:

| Offset | Name         | Access | Reset      | Description                        |
|--------|--------------|--------|------------|------------------------------------|
| `0x0`  | `GPIO_OUT`   | R/W    | `0x0`      | Drives 8-bit GPIO output pins      |
| `0x4`  | `GPIO_IN`    | R only | —          | Returns synchronized GPIO input    |
| `0x8`  | `PWM_CTRL`   | R/W    | `0x0`      | PWM duty cycle (in clock cycles)   |
| `0xC`  | `PWM_PERIOD` | R/W    | `0x0`      | PWM period (in clock cycles)       |

Write strobes are applied per-byte lane. `GPIO_IN` is read-only; a write to `0x4` returns `SLVERR`. Unmapped addresses return `0xDEADBEEF` on read and `SLVERR` on write.

**GPIO Module (`gpio.sv`)**

Drives `gpio_out[7:0]` directly from the `GPIO_OUT` register. Samples `gpio_in[7:0]` through a two-flop synchronizer before presenting it to the register file, preventing metastability on asynchronous external inputs.

**PWM Generator (`pwm.sv`)**

Counter-based PWM. Output is high while the free-running counter is less than the duty value, low otherwise. Counter wraps at the period value. Both duty and period are runtime-programmable through the register file.

```
pwm_out = (counter < duty) ? 1 : 0
counter = (counter == period - 1) ? 0 : counter + 1
```

---

## File Structure

| File                    | Description                                              |
|-------------------------|----------------------------------------------------------|
| `top_axi_gpio_pwm.sv`   | Top-level: integrates AXI slave, regfile, GPIO, PWM     |
| `axi4_slave.sv`         | AXI4-Lite slave — AW/W/B and AR/R channel handling      |
| `regfile.sv`            | Memory-mapped register file with byte-lane write strobes |
| `gpio.sv`               | GPIO output driver and two-flop input synchronizer      |
| `pwm.sv`                | Counter-based PWM generator                             |
| `defines.sv`            | Register offsets, reset values, response codes          |
| `tb_axi_gpio_pwm.sv`    | Directed self-checking testbench (10 test sequences)    |

---

## Testbench

The testbench (`tb_axi_gpio_pwm.sv`) is self-checking with pass/fail reporting on every test. It exercises:

- Simultaneous AW+W write
- AW-before-W with a multi-cycle gap (tests AW latch)
- W-before-AW with a multi-cycle gap (tests W latch)
- `WSTRB` byte masking — write individual bytes, verify others are preserved
- Write to unmapped address → `SLVERR` on B channel
- Write to read-only `GPIO_IN` register → `SLVERR`
- B-channel back-pressure — `BREADY` withheld for several cycles, `BVALID` must hold
- Read from all four valid registers → `RESP_OKAY`
- Read from unmapped address → `SLVERR` + `RDATA = 0xDEADBEEF`
- GPIO input CDC sync — stimulus applied to `gpio_in`, sampled back through `GPIO_IN` register
- PWM duty cycle — period=10, duty=5; output counted over one period, expect ~50% high

All 10 sequences passed in Vivado behavioral simulation.

---

## Key Design Decisions

**AW/W channel decoupling.** AXI4-Lite does not require the master to assert `AWVALID` and `WVALID` in the same cycle — they are independent channels. The slave latches whichever arrives first and waits for the other before issuing the write and response. This prevents write loss on any compliant AXI4-Lite master regardless of channel arrival order.

**Registered `AWREADY`/`WREADY`.** Both ready signals are deasserted while a `BVALID` response is pending. This prevents a new write from being accepted before the previous response has been acknowledged, satisfying the AXI4 rule that a slave must not accept a new transaction while it cannot guarantee a response.

**Two-flop GPIO input synchronizer.** External `gpio_in` is treated as an asynchronous input. A two-flop synchronizer is inserted before the register file to prevent metastability from propagating into the synchronous domain.

---

## What This Does Not Cover

- AXI4 burst transactions (`ARLEN`, `AWLEN` > 0)
- Interrupt generation on GPIO edge or PWM cycle events
- Tri-state GPIO with direction control
- FPGA board implementation (simulation and synthesis only)
- Formal verification or assertion-based coverage

---

## Tools

- **Simulation:** Vivado 2023.x behavioral simulation
- **Synthesis:** Vivado synthesis — clean, no critical warnings
- **Language:** SystemVerilog (IEEE 1800-2017)

---

## Author

Srikanth Muthuvel Ganthimathi
