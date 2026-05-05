import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

@cocotb.test()
async def test_tiny_cpu(dut):
    # Drive a 10MHz clock
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Starting Tiny CPU Test")

    # Initialize inputs
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.rst_n.value = 0

    # Hold reset for 20 cycles to stabilize
    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1
    dut._log.info("Reset Released")

    found_w = False
    
    # Run the CPU and monitor output
    for i in range(50):
        await ClockCycles(dut.clk, 1)
        
        # Wait 1ns for gate delays in GLS to settle before reading
        await Timer(1, unit="ns") 

        # Safely read output, defaulting to 0 if signal is 'X'
        try:
            screen = dut.uo_out.value.to_unsigned()
        except ValueError:
            screen = 0

        # Check for 'W' (0x57)
        if screen == 0x57: 
            dut._log.info(f"Cycle {i}: SUCCESS - Found 'W' (0x57) on screen_out!")
            found_w = True
            break

    assert found_w, f"Test failed: The character 'W' never appeared. Final screen state: {dut.uo_out.value}"
    dut._log.info("Test passed perfectly.")
