clc
clear
close all

load imageBinaryABC.mat

% parameter
dataMat=[];
dataMat2=[];
frame_no = 100;
frame_sz = 1024;
L = round(frame_sz/2); % for ModifyBits func
threshold = 0.05;
skip = 0;
% SX is each segment x
% MatArr is Matrix array
% Modi means modified version
databits = [];
for k=1:9
    groupofuseallframefilename = sprintf('./Output/Data_Output/GroupOfUseAllFrame/GroupOfUseAllFramespeech_%d.mat',k);
    load (groupofuseallframefilename)

    %GroupOfUseAllFrame = GroupArr(k,:);
    cd('Output/Audio_Output/Host_Edited') %Change path for attack
    AudioFile=['speech_' num2str(k) '.wav'];
    [x,fs] = audioread(AudioFile);
    x = x(1:frame_no*frame_sz,1);
    cd ../../..

    % Segmentation and Matrix Transformation
    cd('Tools')

    SX = zeros(frame_sz, frame_no);
    energy = zeros(frame_no,1);
    MatArr = zeros(L, frame_sz-L+1, frame_no);
    for j = 1:frame_no
        SX(:,j) = x(1+frame_sz*(j-1):frame_sz*j);
        energy(j)=sum(SX(:,j).^2);
        MatArr(:,:,j) = Sig2Mat(SX(:,j),L);
    end
    en_normal = normalize(energy,"range");
    cd ..

    for j = 1:frame_no
      if en_normal(j) < threshold
          skip = skip+1;
      else
        % SVD
            [U,D,V] = svd(MatArr(:,:,j));
            i1 = (GroupOfUseAllFrame(j)-1)*32+1;
            i2 = L;

            % calculate r
            Q = 0.5*(i2-i1)*D(i1,i1);
            r = 0;
            diagD = diag(D);
            for n=i1:i2
                r = r + diagD(n);
            end
            r = r/Q;

            if (r < 2/3)
                databits = [databits;0];
            else
                databits = [databits;1];
            end
      end
    end
end

databits1=databits(1:130);
databits2=databits(131:260);
databits3=databits(261:392);

imageBinary = [databits1; databits2; databits3];
% parameters
dataMat(:,1) = databits;
sum = 0;
frame_no = 100;
frame_sz = 1024;
datMat2(:,1)=dataMat((1:392),1);
size_data = size(dataMat2);
row_no = 392;
col_no = 1;
N = row_no*col_no;
% BER
for col = 1:col_no
    for row = 1:row_no
        sum = sum + xor(imageBinary(row),dataMat(row,col));
    end
end
BER = sum/N; % error rate
%Path can be changed individually
cd('Output/Data_Output/DecodedPictures');
    save('databit_no_attack.mat', 'imageBinary'); % Change file name for each attack.
cd ../../..
