clear;
%% System params

sysClkFreq = 50e6;

FsIn = 1e6;   % scaled down by about 5
% FsOut = 1e3;
Fc = 91.4e3;    % scaled down by 5
Fpass = 100;    % Hz
Fstop = 250;    % Hz
Ap = 0.1;       % dB?
Ast = 60;       % dB?

%% DC Block 
dcBlockParams.filterOrder = 4;
dcBlockParams.passbandRipple = 0.1; 
dcBlockParams.stopbandAtten = 70; 
dcBlockParams.normalizedBandwidth = 0.001;

dcBlockFilt = designHighpassIIR( ...
    "FilterOrder", dcBlockParams.filterOrder, ... 
    "StopbandAttenuation", dcBlockParams.stopbandAtten, ...
    "SystemObject", true, ...
    "DesignMethod", "butter", ...
    "HalfPowerFrequency", dcBlockParams.normalizedBandwidth ...
    );
filterAnalyzer(dcBlockFilt, FilterNames="dcBlock");

%% CIC filter
cicParams.DecimationFactor = 128;
cicParams.DifferentialDelay = 1;
cicParams.NumSections = 6;
cicParams.FsOut = FsIn/cicParams.DecimationFactor;

cicFilt = dsp.CICDecimator(cicParams.DecimationFactor, ...
    cicParams.DifferentialDelay,cicParams.NumSections);
cicGain = gain(cicFilt);

cicGainCorr = dsp.FIRFilter('Numerator',1/cicGain);

% create cascade with gain correction and analyze
filterAnalyzer(cicFilt, dsp.FilterCascade(cicFilt, cicGainCorr),  FilterNames={"cic", "cicWithGainCorr"});

%% CIC comp filter
compParams.R = 2;                                % CIC compensation decimation factor
compParams.Fpass = Fstop;                        % CIC compensation passband frequency
compParams.FsOut = cicParams.FsOut/compParams.R; % New sampling rate
compParams.Fstop = compParams.FsOut - Fstop;     % CIC compensation stopband frequency
compParams.Ap = Ap;                              % Same passband ripple as overall filter
compParams.Ast = Ast;                            % Same stopband attenuation as overall filter

compSpec = fdesign.decimator( ...
    compParams.R,'ciccomp', ...
    cicParams.DifferentialDelay, ...
    cicParams.NumSections, ...
    cicParams.DecimationFactor, ...
    'Fp,Fst,Ap,Ast', ...
    compParams.Fpass, compParams.Fstop, compParams.Ap, compParams.Ast, ...
    cicParams.FsOut ...
    );
cicCompFilt = design(compSpec,'SystemObject',true);
% create cascade including compensation and analyze
filterAnalyzer(dsp.FilterCascade(cicFilt,cicGainCorr,cicCompFilt), FilterNames="cicComp");

%% Halfband decimator 
hbParams.FsOut = compParams.FsOut/2;
hbParams.TransitionWidth = hbParams.FsOut - 2*Fstop;
hbParams.StopbandAttenuation = Ast;

hbSpec = fdesign.decimator( ...
    2,'halfband',...
    'Tw,Ast', ...
    hbParams.TransitionWidth, ...
    hbParams.StopbandAttenuation, ...
    compParams.FsOut ...
    );
hbFilt = design(hbSpec,'SystemObject',true);

% cascade of all filter up until this point
filterAnalyzer(dsp.FilterCascade(cicFilt,cicGainCorr,cicCompFilt,hbFilt), FilterNames="halfband");

%% Final FIR 
finalSpec = fdesign.decimator( ...
    2,'lowpass', ...
    'Fp,Fst,Ap,Ast',Fpass,Fstop,Ap,Ast+3,hbParams.FsOut ...
    );
finalFilt = design(finalSpec,'equiripple','SystemObject',true);

% ddcFilterChain           = dsp.FilterCascade(cicFilt,cicGainCorr,cicCompFilt,hbFilt,finalFilt);
% filterAnalyzer(ddcFilterChain);

%% Fixed point conversion 
dcBlockFilt.DenominatorAccumulatorDataType

cicFilt.FixedPointDataType = 'Minimum section word lengths';
cicFilt.OutputWordLength = 18;

% CIC Gain Correction
cicGainCorr.FullPrecisionOverride = false;
cicGainCorr.CoefficientsDataType = 'Custom';
cicGainCorr.CustomCoefficientsDataType = numerictype(fi(cicGainCorr.Numerator,1,16));
cicGainCorr.OutputDataType = 'Custom';
cicGainCorr.CustomOutputDataType = numerictype(1,18,16);

% CIC Droop Compensation
cicCompFilt.FullPrecisionOverride = false;
cicCompFilt.CoefficientsDataType = 'Custom';
cicCompFilt.CustomCoefficientsDataType = numerictype([],16,15);
cicCompFilt.ProductDataType = 'Full precision';
cicCompFilt.AccumulatorDataType = 'Full precision';
cicCompFilt.OutputDataType = 'Custom';
cicCompFilt.CustomOutputDataType = numerictype([],18,16);

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

ddcFilterChain = dsp.FilterCascade( ...
    cicFilt, ...
    cicGainCorr,cicCompFilt,hbFilt,finalFilt);

filterAnalyzer(ddcFilterChain, FilterName="quantizedDdcFilterChain", Arithmetic="fixed");


%% Oscillator

nco.Fd = 1;
nco.AccWL =  nextpow2(FsIn/nco.Fd)+1;
SFDR  = 84;
nco.QuantAccWL = ceil((SFDR-12)/6);
nco.PhaseInc = round((-Fc*2^nco.AccWL)/FsIn);
nco.NumDitherBits = nco.AccWL-nco.QuantAccWL;

% ddcIn = 0;
%
% FrameSize = 1;
%
% modelName = 'FilterChain';
% open_system(modelName);
% set_param(modelName,'SimulationCommand','Update');
% set_param(modelName,'Open','on');
%
% set_param([modelName '/Signal Chain'],'Open','on');
%
% % Initialize random seed before executing any simulations.
% rng(0);
%
% % Generate a 40 kHz test tone, modulated onto the carrier.
% ddcIn = DDCTestUtils.GenerateTestTone(40e3,Fc);
%
% % Demodulate the test signal with the floating-point DDC.
% ddcOut = DDCTestUtils.DownConvert(ddcIn,FsIn,Fc,ddcFilterChain);
% release(ddcFilterChain);
%
% % Demodulate the test signal by running the Simulink model.
% out = sim(modelName);
%
% % Measure the SFDR of the NCO, floating-point DDC outputs, and fixed-point
% % DDC outputs.
% results.sfdrNCO = sfdr(real(out.ncoOut),FsIn);
% results.sfdrFloatDDC = sfdr(real(ddcOut),FsOut);
% results.sfdrFixedDDC = sfdr(real(out.ddcFixedOut),FsOut);
%
% disp('SFDR Measurements');
% disp(['   Floating-point DDC SFDR: ',num2str(results.sfdrFloatDDC) ' dB']);
% disp(['   Fixed-point NCO SFDR: ',num2str(results.sfdrNCO) ' dB']);
% disp(['   Optimized fixed-point DDC SFDR: ',num2str(results.sfdrFixedDDC) ' dB']);
% fprintf(newline);
%
% % Plot the SFDR of the NCO and fixed-point DDC outputs.
% ddcPlots.ncoOutSDFR = figure;
% sfdr(real(out.ncoOut),FsIn);
%
% ddcPlots.OptddcOutSFDR = figure;
% sfdr(real(out.ddcFixedOut),FsOut);
