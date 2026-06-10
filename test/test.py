# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

SCLK_HALF_NS = 50
CSN_SETUP_NS = 50
CSN_HOLD_NS  = 50
SETTLE_NS    = 200

def set_ui_in(dut, sclk=0, mosi=0, csn=1, clr=0):
    """Drive ui_in from named SPI signals for readability."""
    dut.ui_in.value = (
        (sclk << SCLK_BIT) |
        (mosi << MOSI_BIT) |
        (csn  << CSN_BIT)  |
        (clr  << CLR_BIT)
    )

async def tt_reset(dut):
    """Assert TT rst_n to clear the DUT, then release."""
    set_ui_in(dut, csn=1)
    dut.ena.value   = 1
    dut.rst_n.value = 0
    await Timer(200, units="ns")
    dut.rst_n.value = 1
    await Timer(200, units="ns")

async def spi_send_bits(dut, value: int, n_bits: int = 8):
    """Clock n_bits of value MSB-first into ui_in. CSn must already be low."""
    for i in range(n_bits - 1, -1, -1):
        bit = (value >> i) & 1
        set_ui_in(dut, sclk=0, mosi=bit, csn=0)
        await Timer(SCLK_HALF_NS, units="ns")
        set_ui_in(dut, sclk=1, mosi=bit, csn=0)
        await Timer(SCLK_HALF_NS, units="ns")
    set_ui_in(dut, sclk=0, mosi=0, csn=0)

async def spi_transaction(dut, value: int):
    """Full SPI transaction through the TT ui_in bus."""
    set_ui_in(dut, csn=0)
    await Timer(CSN_SETUP_NS, units="ns")
    await spi_send_bits(dut, value)
    await Timer(CSN_HOLD_NS, units="ns")
    set_ui_in(dut, csn=1)                  # CSn rising edge latches the register
    await Timer(SETTLE_NS, units="ns")

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    await tt_reset(dut)
 
    test_values = [0xA5, 0x3C, 0xF0]
 
    for val in test_values:
        await spi_transaction(dut, val)
        observed = int(dut.uo_out.value)
        assert observed == val, (
            f"uo_out mismatch: sent 0x{val:02X}, got 0x{observed:02X}"
        )
        dut._log.info(f"PASS: sent 0x{val:02X} → uo_out=0x{observed:02X}")
