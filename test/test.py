import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, Timer

@cocotb.test()
async def test_tiny_cpu(dut):
    clock = Clock(dut.clk, 100, unit="ns")
    cocotb.start_soon(clock.start())

    dut._log.info("Starting High-Utilization CPU Test")

    dut.ena.value = 1
    
    # We feed 0x57 ('W') into the keyboard input. 
    # reg_a gets 0x57 (Data)
    # reg_b gets 0x57 (Address pointer). 0x57 & 0x3F = Address 23.
    dut.ui_in.value = 0x57 
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 20)
    dut.rst_n.value = 1
    dut._log.info("Reset Released")

    found_w = False
    
    # Increased loop to 60 to give the longer program time to run
    for i in range(60):
        await ClockCycles(dut.clk, 1)
        await Timer(1, unit="ns") 

        try:
            screen = dut.uo_out.value.to_unsigned()
        except ValueError:
            screen = 0

        if screen == 0x57: 
            dut._log.info(f"Cycle {i}: SUCCESS - Found 'W' (0x57) on screen_out!")
            found_w = True
            break

    assert found_w, f"Test failed: The character 'W' never appeared. Final screen state: {dut.uo_out.value}"
    dut._log.info("Test passed perfectly.")
