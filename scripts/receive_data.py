import serial

def main(): 

    ser = serial.Serial("/dev/ttyUSB0", 115_200, 8) 
    c = 0

    while True:
        start = ser.read(1)

        if (int.from_bytes(start) != 0xAA):
            continue
        data = ser.read(2)
        val = float(int.from_bytes(data, byteorder="little"))/256
        end = ser.read(1) 
        if (int.from_bytes(end) != 0xBB): 
            continue
        c += 1
        print(val) 
        # print(f"c: {c}")

if __name__ == "__main__": 
    main()
