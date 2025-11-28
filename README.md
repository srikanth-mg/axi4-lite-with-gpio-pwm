## AXI4-Lite GPIO + PWM Peripheral (SystemVerilog)

This repository contains a fully working AXI4-Lite–based peripheral implemented in SystemVerilog.
It exposes GPIO output, GPIO input sampling, and a configurable PWM generator through a clean AXI4-Lite register interface.

The design was simulated and verified in Vivado using a dedicated testbench that exercises all AXI read/write paths and validates register-level GPIO + PWM behavior.

## 🔧 Architecture Overview:

The peripheral internally contains three sub-blocks:

1. AXI4-Lite Slave Interface:
- Implements write address (AW), write data (W), and write response (B) channels
- Implements read address (AR) and read data (R) channels
- Handles VALID/READY handshaking
- Supports byte-level writes through WSTRB
- Generates write_en and read_en strobes for the register file

2. Register File

Mapped registers:

Offset	Name	Width	Description
- `0x00`	GPIO_OUT	32-bit	Drives 8-bit GPIO output
- `0x04`	GPIO_IN	32-bit	Returns sampled external GPIO inputs
- `0x08`  PWM_CTRL	32-bit	PWM duty cycle
- `0x0C`	PWM_PERIOD	32-bit	PWM period

Handles:

- AXI writes to update registers
- AXI reads to return register values
- Reset initialization
- Default output behavior

3. GPIO Module

- gpio_out: driven by GPIO_OUT register
- gpio_in: sampled into GPIO_IN register
- Used to emulate external hardware inputs/outputs in simulation

4. PWM Generator

Implements a simple counter-based PWM:
- pwm_out = (counter < duty) ? 1 : 0
counter = (counter == period-1) ? 0 : counter + 1

## Files Structure

- `axi_gpio_pwm_top.sv`    - Top-level module integrating AXI, register file, GPIO, and PWM
- `axi_slave_if.sv`         - AXI4-Lite slave interface handling AW/W/B and AR/R channels
- `regfile.sv`              - Memory-mapped register file (GPIO_OUT, GPIO_IN, PWM_CTRL, PWM_PERIOD)
- `gpio.sv`                 - GPIO module that drives output pins and samples input pins
- `pwm.sv`                  - Counter-based PWM generator with runtime duty/period control
- `defines.sv`             - Global constants and register offsets used across modules
- `tb_axi_gpio_pwm_top.sv`  - Testbench verifying AXI read/write + GPIO + PWM behavior
- `wave_axi_write_read.png` - Waveform of AXI write/read + GPIO update + PWM waveform 



## ✔️ Features Implemented

- AXI4-Lite compliant slave interface
- Valid/Ready handshake for all read/write paths
- Full register decode & register file
- GPIO output control
- GPIO input sampling
- Runtime-programmable PWM
- Clean, synthesizable SystemVerilog
- Behavioral simulation verified in Vivado
- End-to-end AXI → Regfile → GPIO/PWM path verified

## 🧪 Simulation Summary

The design is verified using a dedicated SystemVerilog testbench.

Key test sequences:
Write `GPIO_OUT` = 0xAA → verify gpio_out updates
Read back `GPIO_OUT` → confirm AXI read mux
Set `PWM_CTRL` = 100, PWM_PERIOD = 200 → verify PWM output waveform
Read `GPIO_IN` = 0x3C from testbench stimulus
Check all AXI handshakes (AW/W/B/AR/R)

## Observed waveform:
AXI4-Lite Write + Read + GPIO Update + PWM Output

## 🚀 Future Improvements

Possible extensions include:

- Interrupt support for GPIO/pwm events
- AXI burst support (AXI4 full)
- Multiple PWM channels
- Tri-state GPIO with direction control
- APB-bridge or TileLink adaptation
- Synthesis on FPGA board (PWM → real pin)

## 👨‍💻 Author

Srikanth Muthuvel Ganthimathi

## 📜 License

This project is for educational and research purposes.
Modification and extension are encouraged.
