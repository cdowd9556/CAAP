%% code used to prepare the played sine sweep signal and calculate recording length
close all
scale = 1;
[sweep, fs] = audioread("LogSineSweepNew.wav");
sweep = sweep(2:end);
clean = sweep; %% save original version of signal
dt = 1/fs
%%generate signal to be played
sweep = sweep(:); 
sweep = sweep*ones(1, 1);

sweep = sweep.*scale;
zpd = .25*fs;
sweep = [zeros(zpd, 1); sweep;zeros(zpd, 1)];
t = 0:dt:(length(sweep)/fs)-dt;
sweep = sweep';
plot(t, sweep);
soundsc(sweep, fs);
%% (length(sweep)+responseLength)/srate = recording length for capture
%%perform capture here, call function to record response
numRepeats = 1;
responseLength = 4 * fs;
recordSeconds = (length(sweep)+responseLength)/fs;
%%i = 1;                                      %repeats and averages for better signal to noise ratio
%%while i < numRepeats
%     peat = playerandrecord(sweep, fs, outputChl, inputChl, recordSeconds;
%     temp = temp+peat;
%     i = i + 1;
% end
% temp = temp./numRepeats;

%temp = temp';               % switch back to column vector
%temp = temp(zpd+1:length(clean)+responseLength+zpd, 1:lic);        %takes off zeropadding before deconvolution
