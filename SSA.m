[audioData,fs] = audioread("Audio_Source/sample_data.wav");

% Define variables
l = 200;
u = 400;
b = 1;

N = length(audioData);
L = 1024;
K = N - L + 1;
X = zeros(L,K);
for i = 1:K
    X(:,i) = audioData(i:L+i-1);
end
[U,D,V] = svd(X,"vector","econ");

plot(D,"o");
saveas(gcf,'./Plot_Output/Original.png')

% Modify
if b == 1
    modified = D(l);
else
    modified = D(u);
end
D(l:u) = modified;
plot(D,"o");
saveas(gcf,'./Plot_Output/Modified.png')

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

% Write Output
output = normalize(output, 'range', [-1 1]);
audiowrite("Audio_Output/Sample1.wav",output,fs);
