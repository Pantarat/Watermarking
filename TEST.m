FFT_Index_Matrix = zeros(512,512);
for component=1:512
    Signal_component = KeepResult(:,component,20);
    Signal_fft_temp = fft(Signal_component);    % Get Sum signal of group svds and perform FFT
    FFT_Index_Matrix(:,component) = abs(Signal_fft_temp(1:length(Signal_fft_temp)/2));
end

[PCA_coeffs, PCA_scores, PCA_latents] = pca(zscore(FFT_Index_Matrix), 'NumComponents', 10);
PCA_first_coeffs = PCA_coeffs(:,1);
[~,index] = maxk(PCA_first_coeffs, 15);
index = sort(index);

Freq_Grouping = zeros(16,1);


[Freq_Amp,Freq_Rep] = max(FFT_Index_Matrix);

n = 1;
for i = 1:length(index)

    numberofSignalsInGroup = 0;
    product = 1;

    while n <= index(i)
        product = product * Freq_Rep(n);
        numberofSignalsInGroup = numberofSignalsInGroup + 1;
        n = n + 1;
    end

    Freq_Grouping(i) = product ^ (1/numberofSignalsInGroup);
end

plot(Freq_Grouping,'-');

denoised_data = PCA_scores * PCA_coeffs' + mean(FFT_Index_Matrix);

for i = 1:512
    plot(FFT_Index_Matrix(:,i), '-')
    title(num2str(i));
    pause(2);
    close;
end