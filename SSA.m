[audioData,fs] = audioread("Audio_Source/sample_data.wav");

% Define variables
l = 50;
u = 100;
b = '10110';

d_length = length(audioData);
N = 10000;
i = 1;
% separate frame to non-overlapping
F = zeros(N, floor(d_length / N));
while N * i <= d_length
    F(:,i) = audioData(((i - 1) * N + 1) : (i * N));
    i = i + 1;
end

remain = audioData((i-1) * N + 1: end);

Fs = zeros(N, floor(d_length / N));

for j = 1:size(F,2)
    if length(b) >= j
        bit = b(j);
        f = F(:,j);
        L = 500;
        K = N - L + 1;
        X = zeros(L,K);
        for i = 1:K
            X(:,i) = f(i:L+i-1);
        end
        [U,D,V] = svd(X,"vector","econ");
        
        plot_in_name = sprintf('./Plot_Output/Original%d.png',j);
        plot(D,"o");
        saveas(gcf, plot_in_name)
        
        % Modify
        if bit == '1'
            modified = D(l);
        else
            modified = D(u);
        end
        D(l:u) = modified;

        plot_out_name = sprintf('./Plot_Output/Modified%d.png',j);
        plot(D,"o");
        saveas(gcf, plot_out_name)
        
        % Reassemble
        Y = U*diag(D)*V';
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

    Fs(:,j) = output;

end

% concatenate all frames
outData = Fs(:);

% append remaining frame
outData = [outData(:);remain(:)];

% Write Output
outData = normalize(outData, 'range', [-1 1]);
audiowrite("Audio_Output/Sample1.wav",outData,fs);
