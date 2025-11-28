import numpy as np
from tabulate import tabulate
from matplotlib import pyplot as plt

def main(): 

    Rab = 10e3

    codes = np.linspace(0, 255, 256)
    Rwa = calc_Rwa(Rab, codes)
    Rwb = 10e3 - Rwa

    gains = Rwb / Rwa
    gains_dB = 20*np.log(gains)

    print(tabulate(np.column_stack((codes, gains_dB)), ["Code", "Gain (dB)"])) 

    target_gains_dB = np.arange(-16, 37, 4)

    match_idxs = find_gain_matches(gains_dB, target_gains_dB) 

    match_gains = []
    match_codes = []

    for idx in match_idxs: 
        match_gains.append(gains_dB[int(idx)])
        match_codes.append(codes[int(idx)])

    hex_codes = []
    for code in match_codes: 
        hex_codes.append(hex(int(code)))

    print(tabulate(np.column_stack((target_gains_dB, match_gains, hex_codes)), ["Target Gain (dB)", "Actual Gain (dB)", "Code"])) 
    print(hex_codes)

    print(target_gains_dB)

    plt.plot(codes, gains)
    plt.plot(codes, gains_dB)
    plt.show()

def find_gain_matches(gains_dB, target_gains_dB): 
    idxs = np.zeros(len(target_gains_dB))

    target_gain = target_gains_dB[0]
    target_gain_idx = 0

    prev_gain = gains_dB[0]
    for i in range(1, len(gains_dB)): 
        # gain exceeds, we have found match, it is one of two options
        if gains_dB[i] > target_gain: 
            # current is better match
            if calc_error(gains_dB[i], target_gain) < calc_error(prev_gain, target_gain):
                idxs[target_gain_idx] = i
            # if prev is better match
            else: 
                idxs[target_gain_idx] = i - 1

            target_gain_idx += 1

            # have we found the last target 
            if target_gain_idx == len(target_gains_dB): 
                break

            target_gain = target_gains_dB[target_gain_idx]

        prev_gain = gains_dB[i]

    return idxs

def calc_error(actual, target): 
    return np.abs(target - actual) 

@np.vectorize
def calc_Rwa(Rab, code): 
    return (256 - code) / 256 * Rab


if __name__ == "__main__": 
    main()
