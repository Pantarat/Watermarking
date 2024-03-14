% Define the parameters
frequency = 0; % Frequency of the sine wave in Hz
sampling_rate = 1024; % Sampling rate in Hz
duration = 4; % Duration of the signal in seconds
L = 2048;
num_plots = 10;
freq_step = 1;

%Generate the time vector
t = linspace(0, duration, duration * sampling_rate);

cd Tools

% for i=1:num_plots
%     % Generate the sine wave
%     sine_wave = sin(2 * pi * i * freq_step * t) + 0.9*sin(2 * pi * (i+1) * freq_step * t + 100) + 0.8*sin(2 * pi * (i+2) * freq_step * t + 100);
% 
%     traject_mat = Sig2Mat(sine_wave,L);
% 
%     [U,D,V] = svd(traject_mat);
%     subplot(4, 3, i);
%     singular_values = diag(D);
%     scatter(1:50, singular_values(1:50));
%     title(['Frequency: ', num2str(freq_step*(i-1))]);
% end

    num_freq_components = 512;

    sine_wave = zeros(size(t));
    for num_freq=1:num_freq_components
        sine_wave = sine_wave + (num_freq/num_freq_components) * sin(2 * pi * num_freq * t);
    end

    traject_mat = Sig2Mat(sine_wave,L);

    [U,D,V] = svd(traject_mat);

    singular_values = diag(D);
    scatter(1:numel(singular_values), singular_values);


cd ..



% cd('Audio_Source/Host')
%     AudioFile=['Original_' num2str(1) '.wav'];
%     [x,~] = audioread(AudioFile);
% cd ('../..')
% 
% % Preparation
% frame_sz = 1024;
% 
% x = x(10001:(10000+frame_sz));
% Signal_fft_temp = fft(x);
% FFT_Signal = abs(Signal_fft_temp(1:length(Signal_fft_temp)/2));
% 
% [FFT_Signal_Sorted, FFT_Index_Sorted] = sort(FFT_Signal, 'descend');
% 
% % Input frequency
% given_frequency = 35;
% i = find(FFT_Index_Sorted == given_frequency);
% svd_ind = i * 2;
% 
% % Perform SVD
% L = frame_sz/2;
% 
% cd('Tools')
%     traject_signal = Sig2Mat(x, L);
%     [U,D,V] = svd(traject_signal);
%     Result = zeros(frame_sz,1);
% 
%     for k = 1:L
%         Unew = U(:,k);
%         Dnew = D(k,k);
%         Vnew = V(:,k);
%         Vnew = transpose(Vnew);
%         Result(:,k) = Mat2Sig(Dnew*Unew*Vnew,frame_sz,L);
%     end
% 
% cd ..
% 
% % Confirm Hypothesis
% suggested_signal = Result(:,svd_ind);
% svd_fft_temp = fft(suggested_signal);
% svd_FFT_Signal = abs(svd_fft_temp(1:length(svd_fft_temp)/2));
% plot(svd_FFT_Signal)