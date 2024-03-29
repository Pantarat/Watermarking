clear
close all
clc

%This code will produce signal and sum SVD with specific number for every frame

load imageBinaryABC.mat  % Encoded Data
embedPictureIndex=1;

% ---Parameters
fs = 16000;             % Sampling Rate
frame_sz = 1024;        % Number of data points for each frame
frame_no = 100;         % Number of frames to use
L = round(frame_sz/2);  % Set window length for trajectory matrix to half of frame = number of SV components
threshold = 0.05;
beta = 0;               % SMR Threshold
sumindex = 32;          % Number of SV components in a group

frame_szf = 512;                           % Frame size for the PAM model
nfrm = 100;                                % Number of frames for PAM

fine_tune = 0.5;


for sound=1:9

    % ---Load Sounds
    cd('Audio_Source/Host')
    AudioFile=['Original_' num2str(sound) '.wav'];
    [x,~] = audioread(AudioFile);
    cd ('../..')

    fprintf('Finish loading speech %d\n',sound)


    SX = zeros(frame_sz, frame_no);
    energy = zeros(frame_no,1);
    MatArr = zeros(L, frame_sz-L+1, frame_no);
    cd('Tools')
    for j = 1:frame_no
        SX(:,j) = x(1+frame_sz*(j-1):frame_sz*j);       % Setup non-overlapping matrix SX with column=data_in_frame row=#frame
        energy(j)=sum(SX(:,j).^2);                      % Find total energy for each frame store in energy vector
        MatArr(:,:,j) = Sig2Mat(SX(:,j),L);             % Overlap each frame into a trajectory matrix stored in MatArr
    end
    en_normal = normalize(energy,"range");
    cd ..

    fprintf('Finish getting energy of speech %d\n',sound)

    % ---Decompose individual components of SVD to see its interaction with frequency
    % PlotWholeFrameWith no_dat
    Signal_origi=x(1:frame_sz*frame_no);

    % plot group of sub-signal
    cd('Tools')
    Result = zeros(frame_sz, frame_sz/2);
    KeepResult = zeros(frame_sz, frame_sz/2, frame_no);
    for frameMusic=1:frame_no
        [U,D,V] = svd(MatArr(:,:,frameMusic));
        for k = 1:frame_sz/2    % Decompose into frame_sz/2 top components = 1024/2 = 512
            Unew = U(:,k);
            Dnew = D(k,k);
            Vnew = V(:,k);
            Vnew = transpose(Vnew);
            Result(:,k) = Mat2Sig(Dnew*Unew*Vnew,frame_sz,L);
        end
        KeepResult(:,:,frameMusic)=Result;   % frame_sz(reconstructed signal) * #svds * frame_no
    end
    cd ..

    fprintf('Finish SVD and reconstruct of speech %d\n',sound)



    % ---Create groupings of SVD components' signal to determine frequency-index relationship
    NumberOfGroupSignal = (frame_sz / 2) / sumindex;         % Number of groups of svd signals = #svd / group_sz
    GroupOfSubSignalAllframe = zeros(frame_sz, NumberOfGroupSignal, frame_no);

    for ChooseFrameAt = 1:frame_no
        KeepMat = KeepResult(:,:,ChooseFrameAt);  % Get all svd components' matrices of each frame

        startindex = 1;
        for l = 1:NumberOfGroupSignal
            GroupOfSubSignalAllframe(:, l, ChooseFrameAt) = sum(KeepMat(:, startindex:startindex+sumindex-1), 2);
            startindex = startindex + sumindex;
        end
    end
    
    fprintf('Finish grouping SV component matrices of speech %d\n',sound)


    %---Find suitable index to embed with PAM

    % Initialize values
    f = (0 : frame_szf/2-1) / frame_szf*fs;    % Predetermined frequency bins used to map index from SMR

    SXf = zeros(frame_szf, nfrm);
    newSMR = zeros(nfrm, 256);
    allframeindex = zeros(nfrm,1);

    SMR = zeros(nfrm,32);   %SMR of all frames, each with 32 frequencies
    % min_threshold_subband = zeros(nfrm,256);
    frame_psd_dBSPL = zeros(256,nfrm);
    % masking_threshold = zeros(nfrm,256);
    % max_local = zeros(250,nfrm);
    % tonal = zeros(250,nfrm);
    % X_tm_avant = zeros(250,nfrm);
    % X_nm_avant = zeros(250,nfrm);
    % X_tm = zeros(250,nfrm);
    % X_nm = zeros(250,nfrm);
    % newSMR = zeros(nfrm,256);

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

    fprintf('Finish suggesting frequency for speech %d\n',sound)


    %---Find which groups of index (per frame) is suitable for embed

    suggestf = realfreq;
    f_frame = (0:(frame_sz)/2-1)/frame_sz*fs;
    GroupOfUseAllFrame = zeros(1, frame_no);
    GroupOfSubSignal_fft2 = zeros(512, NumberOfGroupSignal);
    index = find(f_frame == suggestf);  % Get index of frame frequency that corresponds to suggested freq from PAM

    % Perform FFT
    for ChooseFrameAt=1:frame_no

        for k=1:NumberOfGroupSignal
            GroupOfSubSignal_fft = fft(GroupOfSubSignalAllframe(:,k,ChooseFrameAt));    % Get Sum signal of group svds and perform FFT
            GroupOfSubSignal_fft2(:,k) = abs(GroupOfSubSignal_fft(1:length(GroupOfSubSignal_fft)/2));   % Get the first half of freqs(BC fft is symmetrical along Y axis) and only get their size
        end

        Normalize_fft2 = mat2gray(GroupOfSubSignal_fft2);   % Normalize to range of 0-1

        for i=1:NumberOfGroupSignal
            Normalize_fft2_pergroup = Normalize_fft2(:,i);  % Get a group of SVD sum signal in freq domain

            % Compare the sum of major freq.(leftside) with masked freq.(rightside)
            LeftSide = sum(Normalize_fft2_pergroup(1:index));
            RightSide = sum(Normalize_fft2_pergroup(index+1:L));
            if RightSide*fine_tune > LeftSide
                % If there is enough sound freq. to the right to be embed without error then set frame to be svd group#
                GroupOfUseAllFrame(:,ChooseFrameAt) = i;
                break
            else
                GroupOfUseAllFrame(:,ChooseFrameAt) = 0;
            end
        end

        % If there is no group that can be used, the last 2 groups will be used
        if GroupOfUseAllFrame(:,ChooseFrameAt) == 0
            GroupOfUseAllFrame(:,ChooseFrameAt) = NumberOfGroupSignal-1;
        end

    end

    fprintf('Finish mapping frequency to index for speech %d\n',sound)


    %---Embedding process
    i2=L;       % modify indices up to the last
    MatArrModi = zeros(L, frame_sz-L+1, frame_no);
    cd('Tools')
    for j = 1:frame_no
        i1 = (GroupOfUseAllFrame(j) - 1) * sumindex + 1;

        % Check if the frame is not silent (has energy above the threshold)
        if en_normal(j) >= threshold
            embedPictureIndexUsed = mod(embedPictureIndex - 1, length(imageBinary)) + 1;

            MatArrModi(:,:,j) = ModifyBitsLinear(MatArr(:,:,j), i1, i2, imageBinary(embedPictureIndexUsed));

            embedPictureIndex = embedPictureIndex + 1;
        else
            % Frame is silent, no modification needed
            MatArrModi(:,:,j) = MatArr(:,:,j);
        end
    end
    cd ..


    %---Reconstruction (convert matrix back to signal)
    cd('Tools')
    yModi = zeros(frame_no, 1);
    for j = 1:frame_no
        yModi(frame_sz*(j-1)+1 : frame_sz*j) = Mat2Sig(MatArrModi(:,:,j),frame_sz,L);
    end
    cd ..


    % audiowrite func to save audio file
    cd('Output/Audio_Output/Host_Edited');
    audiowrite(['speech_' num2str(sound) '.wav'],yModi,fs);
    cd ('../..')

    % Define the base file name
    baseFilename = 'GroupOfUseAllFramespeech';
    % Number to add to the file name
    fileNumber = sound;
    % Create the GroupOfUse file for extract
    filename = sprintf('%s_%d.mat', baseFilename, fileNumber);
    cd('Data_Output/GroupOfUseAllFrame');
    save(filename, 'GroupOfUseAllFrame');
    cd ('../..')
    cd ('../')

    fprintf('Finish embed speech %d\n\n', sound)
end