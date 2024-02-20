[audioData,fs] = audioread("Audio_Source/sample_data.wav");

% Define variables
l = 10;                         % lower boundary to modify
u = 25;                         % upper boundary to modify
b = '10110011101';              % bits to be inserted
L = 50;                         % length of lagged vector

d_length = length(audioData);   % length of audio data
N = 1000;                       % length of frame
                         
% separate data to non-overlapping frame and stores in frame matrix
F = zeros(N, floor(d_length / N));  % initiate frame matrix with 0
i = 1;
while N * i <= d_length
    startindex = ((i - 1) * N + 1);
    endindex = (i * N);
    F(:,i) = audioData(startindex : endindex);  % replace column of 0 with frame (audio data)
    i = i + 1;
end

remain = audioData((i-1) * N + 1: end);         % remainder of audio data

Fs = zeros(N, floor(d_length / N));     % initiate modified frame matrix

% embed data (b)
for j = 1:size(F,2)
    if length(b) >= j
        bit = b(j);                     % get the bit
        f = F(:,j);                     % get the frame
        K = N - L + 1;                  % number of columns of hankel matrix
        X = zeros(L,K);                 % initiate hankel matrix

        % create hankel matrix from frame
        for i = 1:K
            X(:,i) = f(i:L+i-1);
        end

        % SVD
        [U,D,V] = svd(X,"vector");
        
        % plot original sqrt of eigen values
        plot_in_name = sprintf('./Output/Plot_Output/Original%d.png',j);
        plot(D,"o");
        saveas(gcf, plot_in_name)
        
        % Modify
        if bit == '1'
            modified = D(l);        % get the sqrt of eigen value at the lower boundary
        else
            modified = D(u);        % get the sqrt of eigen value at the upper boundary
        end
        D(l:u) = modified;          % modify the eigen value from lower to upper boundary

        % plot modified sqrt of eigen values
        plot_out_name = sprintf('./Output/Plot_Output/Modified%d.png',j);
        plot(D,"o");
        saveas(gcf, plot_out_name)
        
        % Reassemble
        D_matrix = diag(D);
        
        % Reconstruct the matrix Y
        Y = U*diag(D)*V(:,1:size(U,1))';
        output = zeros(N,1);
        
        Ls = size(X,1);
        Ks = N - Ls + 1;
        
        % Hankelize
        for k = 1:Ls-1
            sum = 0;
            for m = 1:k
                sum = sum + Y(m,k-m+1);
            end
            output(k) = (1/k)*sum;
        end
        for k = Ls:Ks
            sum = 0;
            for m = 1:Ls-1
                sum = sum + Y(m,k-m+1);
            end
            output(k) = (1/Ls-1)*sum;
        end
        for k = Ks+1:N
            sum = 0;
            for m = k-Ks+1:N-Ks+1
                sum = sum + Y(m,k-m+1);
            end
            output(k) = (1/(N-k+1))*sum;
        end
    else
        output = F(:,j);
    end

    Fs(:,j) = output;           % append the modified frame to Fs

end

% concatenate all frames
outData = Fs(:);

% append remaining frame
outData = [outData(:);remain(:)];

% Write Output
outData = normalize(outData, 'range', [-1 1]);
audiowrite("Output/Audio_Output/Sample1.wav",outData,fs);
