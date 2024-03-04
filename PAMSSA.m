clear
close all

%This code will produce signal and sum SVD with specific number for every frame

load imageBinaryABC.mat  % Encoded Data
embedPictureIndex=1;

% ---Parameters
fs = 16000;             % Sampling Rate
frame_sz = 1024;        % Number of data points for each frame
frame_no = 100;         % Number of frames to use
f_whole = (0 : (frame_sz*frame_no)/2-1) / frame_sz*fs;  % frequency range from 0 to the Nyquist frequency (Half of sampling rate)
L = round(frame_sz/2);  % Set window length for trajectory matrix to half of frame.
threshold = 0.05;
smr = 0;


for sound=1:9

    % ---Load Sounds
    cd('Audio_Source/Host')
        AudioFile=['Original_' num2str(sound) '.wav'];
        [x,~] = audioread(AudioFile);
    cd ../..



    SX = zeros(frame_sz, frame_no);
    energy = zeros(frame_no);
    MatArr = zeros(L, frame_sz-L+1, frame_no);
    cd('Tools')
        for j = 1:frame_no
            SX(:,j) = x(1+frame_sz*(j-1):frame_sz*j);       % Setup non-overlapping matrix SX with column=data_in_frame row=#frame
            energy(j)=sum(SX(:,j).^2);                      % Find total energy for each frame store in energy vector
            MatArr(:,:,j) = Sig2Mat(SX(:,j),L);             % Overlap each frame into a trajectory matrix stored in MatArr
        end
        en_normal = normalize(energy,"range");
    cd ..
    
        % ---Decompose and plot individual components of SVD to see its interaction with frequency
        % PlotWholeFrameWith no_dat
        Signal_origi=x(1:frame_sz*frame_no);

        % plot group of sub-signal
        cd('Tools')
        Result = zeros(frame_sz, frame_sz/2);
        KeepResult = zeros(frame_sz, frame_sz/2, frame_no);
        for frameMusic=1:frame_no
            Sumresult=0;
            [U,D,V] = svd(MatArr(:,:,frameMusic));
            for k = 1:frame_sz/2
                    Unew = U(:,k);
                    Dnew = D(k,k);
                    Vnew = V(:,k);
                    Vnew = transpose(Vnew);
                    Result(:,k) = Mat2Sig(Dnew*Unew*Vnew,frame_sz,L);
            end
            KeepResult(:,:,frameMusic)=Result; %all frame
        end
        cd .. 

    
        % ---?????????
        %choose signal for every frame and Collect every group of sum-sub-signal in to the matrix
        newSumSignal=[];
        sumindex=32;
        NumberOfGroupSignal = L/sumindex;
        for ChooseFrameAt = 1:frame_no
            KeepMat=KeepResult(:,:,ChooseFrameAt);
            startindex=1;
            sumindex=32;
            storesum=sumindex;
            for l=1:NumberOfGroupSignal
                newSig=zeros(frame_sz,1);
                for k=startindex:sumindex
                   newSig=KeepMat(:,k)+newSig;
                end
                startindex=startindex+storesum;
                sumindex=sumindex+storesum-1;
                GroupOfSubSignalAllframe(:,l,ChooseFrameAt) =  newSig;
            end
    
        end


    %The following section will find the most suitable freq for the sound parameter
     frame_szf = 512;                           % Frame size for the PAM model
     Lf = round(frame_szf/2);                   % Window Length is half of frame size
     f = (0:frame_szf/2-1)/frame_szf*fs;
     nfrm = 100;
     Feq=zeros(2,nfrm);
     SMR=zeros(nfrm,32);
     min_threshold_subband=zeros(nfrm,256);
     frame_psd_dBSPL=zeros(256,nfrm);
     masking_threshold=zeros(nfrm,256);
     max_local=zeros(250,nfrm);
     tonal=zeros(250,nfrm);
     X_tm_avant=zeros(250,nfrm);
     X_nm_avant=zeros(250,nfrm);
     X_tm=zeros(250,nfrm);
     X_nm=zeros(250,nfrm);
     newSMR = zeros(nfrm,256);
    allframefreq=[];
    embedF=[];
    xf = x(1:frame_no*frame_szf,1);
    for i = 1:frame_no
        SXf(:,i) = xf(1+frame_szf*(i-1):frame_szf*i);
        %find SMR and frame_psd
        cd Tools
        [SMR(i,:), min_threshold_subband(i,:), frame_psd_dBSPL(:,i), masking_threshold(i,:),max_local(:,i),tonal(:,i),X_tm_avant(:,i),X_nm_avant(:,i),X_tm(:,i),X_nm(:,i)] = MPEG1_psycho_acoustic_model1JK(SXf(:,i));
        cd ..
        for j = 1:256
            newSMR(i,j) = SMR(i,ceil(j/8));
        end
        % check to suitable frequency for embed (smr less than psd)
        keepindex=0;
        index=256;
        while newSMR(i,index) < smr & index > 1
            keepindex=index;
            index=index-1;
        end
        allframeindex(i)=keepindex;
    end

    % use most index to start embed
    usedindex = mean(allframeindex);
    usedindex = round(usedindex);
    realfreq = f(usedindex);
    
    %This code will find which groups of index (per frame) is suitable for embed
    suggestf = realfreq;
    fine_tune = 0.5;
    f_frame = (0:(frame_sz)/2-1)/frame_sz*fs;
    GroupOfUseAllFrame=[];
    sumindex=32;
    NumberOfGroupSignal = L/sumindex;
    %Perform FFT
    for ChooseFrameAt=1:frame_no
    
        for k=1:NumberOfGroupSignal
            GroupOfSubSignal_fft = fft(GroupOfSubSignalAllframe(:,k,ChooseFrameAt));
            GroupOfSubSignal_fft2(:,k) = abs(GroupOfSubSignal_fft(1:length(GroupOfSubSignal_fft)/2));
        end
            Normalize_fft2 = mat2gray(GroupOfSubSignal_fft2);
            for i=1:NumberOfGroupSignal
                index = find(f_frame == suggestf);
                Normalize_fft2_pergroup = Normalize_fft2(:,i);
                CuttingPointY = Normalize_fft2_pergroup(index);
                LeftSide = sum(Normalize_fft2_pergroup(1:index));
                RightSide = sum(Normalize_fft2_pergroup(index+1:L));
                if RightSide*fine_tune > LeftSide % less than or more than?
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
    
        sumindex=32;
        i1=1;
        i2=L;
        MatArrModi = [];
        cd('Tools')
        skip=0;
        for j = 1:frame_no
           i1 = (GroupOfUseAllFrame(j)-1)*sumindex+1;
           %i2 = i1+31;
    
           %check if the frame is silence
            if en_normal(j) < threshold
                skip=skip+1;
                MatArrModi(:,:,j) = MatArr(:,:,j);
            else
                embedPictureIndexUsed=embedPictureIndex-skip;
                if embedPictureIndexUsed>length(imageBinary)
                    embedPictureIndexUsed=1;
                end
                MatArrModi(:,:,j) = ModifyBitsLinear(MatArr(:,:,j),i1,i2,imageBinary(embedPictureIndexUsed)); % Modify using i1 and i2
            end
            embedPictureIndex=embedPictureIndex+1;
        end
        cd ..
    
        % Reconstruction (convert matrix back to signal)
        cd('Tools')
        y = [];
        yModi = [];
        for j = 1:frame_no
            SYModi(:,j) = Mat2Sig(MatArrModi(:,:,j),frame_sz,L);
            yModi = [yModi;SYModi(:,j)];
        end
        cd ..
    
    
        % audiowrite func to save audio file
         cd('Output/Audio_Output/Host_Edited');
            audiowrite(['speech_' num2str(sound) '.wav'],yModi,fs);
         cd ../..
         % Define the base file name
         baseFilename = 'GroupOfUseAllFramespeech';
         % Number to add to the file name
         fileNumber = sound;
         % Create the GroupOfUse file for extract
         filename = sprintf('%s_%d.mat', baseFilename, fileNumber);
         cd('Data_Output/GroupOfUseAllFrame');
            save(filename, 'GroupOfUseAllFrame');
         cd ../..
         cd ..
         
         disp('Finish embed speech ');
end