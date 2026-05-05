## How it works
This project is a minimalist 8-bit CPU optimized for a tiny 1x2 tile silicon footprint. To achieve this size, the design offloads data storage to an external memory bus using the bidirectional I/O (UIO) pins.

The CPU features a custom instruction set and an Arithmetic Logic Unit (ALU) capable of addition and subtraction. It operates by broadcasting memory addresses on the uio_out pins and reading the corresponding data from the uio_in pins. This allows the processor to maintain functional capacity for word-processing logic without the heavy area cost of internal silicon registers.

## How to test
To test the project, apply a clock signal to the clk pin and pull rst_n low to initialize the program counter. Because the RAM is external, the test environment (or physical hardware) must provide data on the uio_in pins in response to the addresses appearing on uio_out.

Provide input characters or opcodes via ui_in.

Observe processed character data on uo_out.

Monitor the uio bus to ensure proper memory addressing.

Run the Cocotb test.py script, which simulates this external memory loopback to verify logic accuracy.

## External hardware
This project requires external hardware to function as the data memory:

External Storage: An SRAM chip or a microcontroller (like an Arduino or RP2040) configured to act as a memory provider for the 8-bit UIO bus.

Interface: A standard TinyTapeout demo board or a breadboard with 3.3V I/O.

Optional: An 8-bit LED bank or logic analyzer to visualize the bus activity and CPU output in real-time.
