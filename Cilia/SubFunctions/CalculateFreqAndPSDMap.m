
function [Freq,Freq_FromPSD]=CalculateFreqAndPSDMap(Ima,Sz,nn,AcqFreq)

Freq=zeros(Sz.NLines,Sz.NCol,5);
Freq_FromPSD=zeros(Sz.NLines,Sz.NCol,5);
h=waitbar(0,strcat('Frequency Calculation File #',num2str(nn)));
% It calculates the Fourier transform of the time profile of each pixel in
% the image + finds the maxima of the Fourier transform. If peaks are
% found, the peaks are sorted and saved in a FrequencyMap

for ll=1:Sz.NLines
    waitbar(ll/Sz.NLines,h);
    for cc=1:Sz.NCol
        F=fft(squeeze(Ima(ll,cc,:)/max(Ima(ll,cc,:))));
        PSD=F.*conj(F);%Power Spectral density
        Abs_F=smooth(abs(F(2:floor(end/2))));
        
        [~,LocalFreq]=findpeaks(Abs_F,'MinPeakDistance',10,'NPeaks',5,'SortStr','descend');
        [~,LocalFreq2]=findpeaks(PSD(2:floor(end/2)),'MinPeakDistance',10,'NPeaks',5,'SortStr','descend');
        LocalFreq=LocalFreq*AcqFreq/(length(F)-1);
        LocalFreq2=LocalFreq2*AcqFreq/(length(F)-1);
        Freq(ll,cc,:)=LocalFreq;
        Freq_FromPSD(ll,cc,:)=LocalFreq2;
        
        
        
    end
end
close(h)
end