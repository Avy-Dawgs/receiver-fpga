
import serial
import numpy as np

def main(): 

    ser = serial.Serial("/dev/ttyUSB0", 115_200, 8) 
    c = 0

    vals = []

    while True:
        start = ser.read(1)

        if (int.from_bytes(start) != 0xAA):
            continue
        data = ser.read(4)
        end = ser.read(1) 
        if (int.from_bytes(end) != 0xBB): 
            continue
        c += 1
        data_int = int.from_bytes(data, byteorder='little')
        val = float(data_int) * 2**-28
        vals.append(val)

        if c == 1000: 
            print(f"mean: {np.mean(vals)}")
            print(f"max: {np.max(vals)}")
            c = 0
            vals.clear()


if __name__ == "__main__": 
    main()
