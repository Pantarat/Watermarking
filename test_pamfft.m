load imageBinaryABC.mat  % Encoded Data
embedPictureIndex=1;

% ---Parameters
frame_sz = 1024;        % Number of data points for each frame
frame_no = 100;         % Number of frames to use
L = round(frame_sz/2);  % Set window length for trajectory matrix to half of frame = number of SV components
threshold = 0.05;
beta = 0;               % SMR Threshold
sumindex = 32;          % Number of SV components in a group
frame_szf = 512;        % Frame size for the PAM model
nfrm = 100;             % Number of frames for PAM
fine_tune = 0.5;

% ---Load Sounds
    cd('Audio_Source/Host')
        AudioFile=['Original_' num2str(1) '.wav']; %change num for each audio file
        [x,fs] = audioread(AudioFile);
    cd ('../..')
   
%---Find suitable index to embed with PAM

% Initialize values
    f = (0 : frame_szf/2-1) / frame_szf*fs;    % Predetermined frequency bins used to map index from SMR
    SXf = zeros(frame_szf, nfrm);
    newSMR = zeros(nfrm, 256);
    allframeindex = zeros(nfrm,1);

    SMR = zeros(nfrm,32);   %SMR of all frames, each with 32 frequencies
    frame_psd_dBSPL = zeros(256,nfrm);

    xf = x(1:nfrm*frame_szf,1); % Get original signal from first up to last frame (frame_no * frame_szf)
    for i = 1:nfrm
        SXf(:,i) = xf(1+frame_szf*(i-1):frame_szf*i);   % Split original signal into non-overlapping frames
        %find SMR and frame_psd
        cd('Tools')
        [   SMR(i,:), ...
            ~, ...
            frame_psd_dBSPL(:,i), ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~, ...
            ~ ...
            ] = MPEG1_psycho_acoustic_model1JK(SXf(:,i));   % Get signal-to-mask ratio of each frame
        cd ..

        % Spread the SMR into 8 identicle SMR for each frequency to increase resolution
        for j = 1:256
            newSMR(i,j) = SMR(i,ceil(j/8));
        end

        % check to suitable frequency for embed (smr less than psd)
        keepindex=0;
        index=256;
        % Note: SMR generally decreases for higher freqs b/c human cannot hear high freqs well
        % Find the highest SMR below the set threshold and get its index
        while newSMR(i,index) < beta & index > 1
            keepindex=index;
            index=index-1;
        end
        allframeindex(i)=keepindex;
    end

    % use mean index of all frames closest to threshold to start embed
    usedindex = round(mean(allframeindex));
    realfreq = f(usedindex);

    fprintf('Finish suggesting frequency for speech \n')
    fprintf('%d Hz \n',realfreq)

    x = x(10001:(10000+frame_sz));
    Signal_fft_temp = fft(x);
    FFT_Signal = abs(Signal_fft_temp(1:length(Signal_fft_temp)/2));

    plot(fs/length(FFT_Signal)*(0:L-1),FFT_Signal,"LineWidth",1)
    xline(round(realfreq))
    xlabel("f (Hz)")
    ylabel("|fft(X)|")