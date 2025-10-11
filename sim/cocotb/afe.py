'''
Analog front end models.
'''

import cocotb 
from cocotb.queue import Queue 
from cocotb.triggers import Timer 

class HGA: 
    '''
    Model of HGA.
    '''

    def __init__(
            self, 
            in_queue: Queue, 
            out_queue: Queue
            ): 
        self.in_queue = in_queue 
        self.out_queue = out_queue 
        self._bypass = True
        self.gain = 100

        cocotb.start_soon(self.run())

    @property 
    def bypass(self) -> bool: 
        return self._bypass

    @bypass.setter 
    def bypass(self, val: bool): 
        self._bypass = val

    async def run(self): 
        while True: 
            in_val = await self.in_queue.get() 
            if self._bypass: 
                out_val = in_val 
            else: 
                out_val = in_val * self.gain
            await self.out_queue.put(out_val)

class PGA: 
    '''
    Model of PGA.
    '''

    def __init__(
            self, 
            init_gain: float, 
            in_queue: Queue, 
            out_queue: Queue
            ): 
        self._gain = init_gain 
        self.in_queue = in_queue 
        self.out_queue = out_queue 

        cocotb.start_soon(self.run()) 

        @property 
        def gain(self) -> float: 
            return self._gain 

        @gain.setter 
        def gain(self, val): 
            self._gain = val

        async def run(self): 
            '''
            Run the model.
            '''
            while True: 
                in_val = await self.in_queue.get() 
                self.out_queue.put(in_val * self._gain)

class ADC: 
    '''
    Model of ADC.
    '''

    def __init__(
            self, 
            ref_V: float, 
            bits: int, 
            in_queue: Queue, 
            out_queue: Queue
            ): 
        self.ref_V = ref_V 
        self.min_val = 0 
        self.max_val = 2**bits - 1 
        self.in_queue = in_queue 
        self.out_queue = out_queue 

        cocotb.start_soon(self.run()) 

        async def run(self) -> None: 
            '''
            Run the model.
            '''
            while True: 
                in_val = await self.in_queue.git() 
                out = int((in_val / self.ref_val) * self.max_val) 
                await self.out_queue.put(min(max(self.min_val, out), self.max_val))

class AFE: 
    '''
    Model of AFE. 
    '''

    def __init__(
            self, 
            in_queue: Queue, 
            out_queue: Queue
            ): 
        self.in_queue = in_queue 
        self.out_queue = out_queue 
        self.pga_to_adc_queue = Queue() 
        self.hga_to_pga_queue = Queue

        self.hga = HGA(self.in_queue, self.hga_to_pga_queue)
        self.pga = PGA(5, self.hga_to_pga_queue, self.pga_to_adc_queue)
        self.adc = ADC(5, 12, self.pga_to_adc_queue, self.out_queue)
