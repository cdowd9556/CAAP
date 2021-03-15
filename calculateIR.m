
function y = decsweep(recorded, cleansweep)
%convolves with amplitude modulate inverse sweep to provide IR
lic = 1
fs = 44100
scale = 1;
low = 100;
hi = 15000;
signalLengthN = 220500; 
signalLength = 5;
responseLength = 4 * fs;
%%we flip sweep to make inverse
rsweep = cleansweep*ones(1,lic);
rsweep = flip(rsweep);
t = (0:1:signalLengthN-1)'/fs;
R = log(hi/low);
k = exp(t*R/signalLengthN*fs)*scale;
rsweep = rsweep./k;

rsweep = [zeros(.5*fs, lic);rsweep;zeros(.5*fs, lic)]; %zeropadding sweep before inverse removes artifacts

%rsweep = real(ifft(1./fft(rsweep)));
la = length(recorded);
lb = length(rsweep);
rsweep = [rsweep; zeros(lb-1, lic)]; %zeropadding before conv
% 
% 
recorded = [recorded; zeros(la-1, lic)];
% a = fft(rsweep, 2^nextpow2(length(recorded))); %much faster than conv function because of pow2's
% b= fft(recorded, 2^nextpow2(length(recorded)));
% y = ifft(a.*b);
% using conv instead 
y = conv(rsweep, recorded);
y= y(fs*(signalLength+.5)+1:fs*(signalLength+.5)+responseLength,1:lic);
end