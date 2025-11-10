clear;
%% System params

sysClkFreq = 50e6;


FsIn = 5e6;
% FsOut = 1e3;
Fc = 45.7e3;
Fpass = 100; 
Fstop = 250;
Ap = 0.1;
Ast = 60;

%% DC Block 

dcBlockParams.passbandRipple = 0.1; 
dcBlockParams.stopbandAtten = -60; 
dcBlockParams.

%% CIC filter
cicParams.DecimationFactor = 512;
cicParams.DifferentialDelay = 1;
cicParams.NumSections = 4;
cicParams.FsOut = FsIn/cicParams.DecimationFactor;

cicFilt = dsp.CICDecimator(cicParams.DecimationFactor, ...
    cicParams.DifferentialDelay,cicParams.NumSections)
cicGain = gain(cicFilt);

cicGainCorr = dsp.FIRFilter('Numerator',1/cicGain);

ddcPlots.cicDecim = fvtool(...
    cicFilt, ...
    dsp.FilterCascade(cicFilt,cicGainCorr), ...
    'Fs',[FsIn,FsIn]);
legend(ddcPlots.cicDecim, ...
    'CIC No Correction', ...
    'CIC With Gain Correction');

%% CIC comp filter

compParams.R = 2;                                % CIC compensation decimation factor
compParams.Fpass = Fstop;                        % CIC compensation passband frequency
compParams.FsOut = cicParams.FsOut/compParams.R; % New sampling rate
compParams.Fstop = compParams.FsOut - Fstop;     % CIC compensation stopband frequency
compParams.Ap = Ap;                              % Same passband ripple as overall filter
compParams.Ast = Ast;                            % Same stopband attenuation as overall filter

compSpec = fdesign.decimator(compParams.R,'ciccomp', ...
    cicParams.DifferentialDelay, ...
    cicParams.NumSections, ...
    cicParams.DecimationFactor, ...
    'Fp,Fst,Ap,Ast', ...
    compParams.Fpass,compParams.Fstop,compParams.Ap,compParams.Ast, ...
    cicParams.FsOut)
compFilt = design(compSpec,'SystemObject',true);

ddcPlots.cicComp = fvtool(...
    dsp.FilterCascade(cicFilt,cicGainCorr,compFilt), ...
    'Fs',FsIn,'Legend','off');

%% Halfband decimator 

hbParams.FsOut = compParams.FsOut/2;
hbParams.TransitionWidth = hbParams.FsOut - 2*Fstop;
hbParams.StopbandAttenuation = Ast;

hbSpec = fdesign.decimator(2,'halfband',...
    'Tw,Ast', ...
    hbParams.TransitionWidth, ...
    hbParams.StopbandAttenuation, ...
    compParams.FsOut)
hbFilt = design(hbSpec,'SystemObject',true);

ddcPlots.halfbandFIR = fvtool(...
    dsp.FilterCascade(cicFilt,cicGainCorr,compFilt,hbFilt), ...
    'Fs',FsIn,'Legend','off');

%% Final FIR 

finalSpec = fdesign.decimator(2,'lowpass', ...
    'Fp,Fst,Ap,Ast',Fpass,Fstop,Ap,Ast+3,hbParams.FsOut)
finalFilt = design(finalSpec,'equiripple','SystemObject',true)

%% Filter chain

ddcFilterChain           = dsp.FilterCascade(cicFilt,cicGainCorr,compFilt,hbFilt,finalFilt);
ddcPlots.overallResponse = fvtool(ddcFilterChain,'Fs',FsIn,'Legend','off');

%% Fixed point conversion 

cicFilt.FixedPointDataType = 'Minimum section word lengths';
cicFilt.OutputWordLength = 18;

% CIC Gain Correction
cicGainCorr.FullPrecisionOverride = false;
cicGainCorr.CoefficientsDataType = 'Custom';
cicGainCorr.CustomCoefficientsDataType = numerictype(fi(cicGainCorr.Numerator,1,16));
cicGainCorr.OutputDataType = 'Custom';
cicGainCorr.CustomOutputDataType = numerictype(1,18,16);

% CIC Droop Compensation
compFilt.FullPrecisionOverride = false;
compFilt.CoefficientsDataType = 'Custom';
compFilt.CustomCoefficientsDataType = numerictype([],16,15);
compFilt.ProductDataType = 'Full precision';
compFilt.AccumulatorDataType = 'Full precision';
compFilt.OutputDataType = 'Custom';
compFilt.CustomOutputDataType = numerictype([],18,16);

% Halfband
hbFilt.FullPrecisionOverride = false;
hbFilt.CoefficientsDataType = 'Custom';
hbFilt.CustomCoefficientsDataType = numerictype([],16,15);
hbFilt.ProductDataType = 'Full precision';
hbFilt.AccumulatorDataType = 'Full precision';
hbFilt.OutputDataType = 'Custom';
hbFilt.CustomOutputDataType = numerictype([],18,16);

% FIR
finalFilt.FullPrecisionOverride = false;
finalFilt.CoefficientsDataType = 'Custom';
finalFilt.CustomCoefficientsDataType = numerictype([],16,15);
finalFilt.ProductDataType = 'Full precision';
finalFilt.AccumulatorDataType = 'Full precision';
finalFilt.OutputDataType = 'Custom';
finalFilt.CustomOutputDataType = numerictype([],18,16);

% ddcPlots.quantizedFIR = fvtool(finalFilt, ...
%     'Fs',hbParams.FsOut,'arithmetic','fixed');

ddcFilterChain = dsp.FilterCascade(cicFilt, ...
    cicGainCorr,compFilt,hbFilt,finalFilt)
ddcPlots.quantizedDDCResponse = fvtool(ddcFilterChain, ...
    'Fs',FsIn,'Arithmetic','fixed');

legend(ddcPlots.quantizedDDCResponse, ...
    'DDC filter chain');

%% Simulink Model 

nco.Fd = 1;
nco.AccWL =  nextpow2(FsIn/nco.Fd)+1;
SFDR  = 84;
nco.QuantAccWL = ceil((SFDR-12)/6);
nco.PhaseInc = round((-Fc*2^nco.AccWL)/FsIn);
nco.NumDitherBits = nco.AccWL-nco.QuantAccWL;

ddcIn = 0;

FrameSize = 4;

modelName = 'DDCforLTEHDL';
open_system(modelName);
set_param(modelName,'SimulationCommand','Update');
set_param(modelName,'Open','on');

set_param([modelName '/HDL_DDC'],'Open','on');

% Initialize random seed before executing any simulations.
rng(0);

% Generate a 40 kHz test tone, modulated onto the carrier.
ddcIn = DDCTestUtils.GenerateTestTone(40e3,Fc);

% Demodulate the test signal with the floating-point DDC.
ddcOut = DDCTestUtils.DownConvert(ddcIn,FsIn,Fc,ddcFilterChain);
release(ddcFilterChain);

% Demodulate the test signal by running the Simulink model.
out = sim(modelName);

% Measure the SFDR of the NCO, floating-point DDC outputs, and fixed-point
% DDC outputs.
results.sfdrNCO = sfdr(real(out.ncoOut),FsIn);
results.sfdrFloatDDC = sfdr(real(ddcOut),FsOut);
results.sfdrFixedDDC = sfdr(real(out.ddcFixedOut),FsOut);

disp('SFDR Measurements');
disp(['   Floating-point DDC SFDR: ',num2str(results.sfdrFloatDDC) ' dB']);
disp(['   Fixed-point NCO SFDR: ',num2str(results.sfdrNCO) ' dB']);
disp(['   Optimized fixed-point DDC SFDR: ',num2str(results.sfdrFixedDDC) ' dB']);
fprintf(newline);

% Plot the SFDR of the NCO and fixed-point DDC outputs.
ddcPlots.ncoOutSDFR = figure;
sfdr(real(out.ncoOut),FsIn);

ddcPlots.OptddcOutSFDR = figure;
sfdr(real(out.ddcFixedOut),FsOut);
