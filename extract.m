% Load Data
[audioData,fs] = audioread('./Output/Audio_Output/Sample1.wav');

% Define variables
l = 10;
u = 25;
frame_no = 11;
L = 50;

d_length = length(audioData);
N = 1000;
i = 1;

% separate frame to non-overlapping
F = zeros(N, floor(d_length / N));
while N * i <= d_length
    F(:,i) = audioData(((i - 1) * N + 1) : (i * N));
    i = i + 1;
end

% Initialize values
databits = [];


for j = 1:frame_no

    % Matrix Transformation
    f = F(:,j);
    K = N - L + 1;
    X = zeros(L,K);
    for i = 1:K
        X(:,i) = f(i:L+i-1);
    end

    % SVD to find singular spectrum and extract bit
    [U,D,V] = svd(X,"vector","econ");

    newX = l:u;
    newY = D;
    newY = newY(l:u);
    p = polyfit(newX,newY,2);
    if (p(1) > 0)
        databits = [databits;0];
    else
        databits = [databits;1];
    end
end

save("Output/Data_Output/encoded_data_Sample1.mat","databits")