close all
scale = 2
recorded = audioread("testResponse.wav");
recorded = recorded(:,1);
recorded = recorded(2: end);

fs = 44100;
responseLength = 4 * fs;

clean = audioread("LogSineSweepNew.wav");
clean = clean .* scale;
clean = clean(2: end);
IR = calculateIR(recorded, clean);
t = 0 : 1/44100 : length(IR)/fs - (1/44100);
plot(t, IR);

