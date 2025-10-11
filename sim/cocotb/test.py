from afe import AFE 

import cocotb 
from cocotb.clock import Clock 
from cocotb.queue import Queue 
from cocotb.triggers import RisingEdge, Timer, ValueChange

import numpy as np

async def hga_set(dut, afe): 
    '''
    Listen for change in HGA bypass and update.
    '''
    while True: 
        await ValueChange(dut.hga_bypass) 
        if dut.hga_bypass.value == 0: 
            afe.hga.bypass = False
        else: 
            afe.hga.bypass = True

async def pga_set(dut, afe): 
    '''
    Listen for change in PGA gain and update.
    '''
    while True: 
        await ValueChange(dut.pga_gain) 
        afe.pga.gain = 10**(dut.pga_gain()/20)

async def generate_signal(afe): 
    '''
    Generate signal and feed into afe. 
    '''
    while True: 
        sample_period = 1/5e6
        time = 0
        await Timer(sample_period, "sec")
        time += sample_period
        val = 0.01 * np.cos(2 * np.pi * 457e3 * time)
        afe.in_queue.put(val)

async def read_data(dut):
    '''
    Read data from the device.
    '''
    while True: 
        await ValueChange(dut.some_val)
        # collect value and place it into array? (plotting is a separete concern i think)

@cocotb.test()
async def test_dut(dut): 
    '''
    Test entry point.
    '''

    clk_freq = 125e6
    clk_period = 1/clk_freq
    clk = Clock(dut.clk, clk_period, "sec")
    cocotb.start_soon(clk.start()) 

    afe_in_queue = Queue() 
    afe_out_queue = Queue() 

    afe = AFE(afe_in_queue, afe_out_queue) 

    cocotb.start_soon(pga_set(dut, afe)) 
    cocotb.start_soon(hga_set(dut, afe)) 
    cocotb.start_soon(read_data(dut))
