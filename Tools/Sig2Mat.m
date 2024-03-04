function X = Sig2Mat(x,L)

% The trajectory matrix X is builded from 
% a signal x, given the window lenght L.
% Dimension of X is L x K, where N is the 
% length of x, and K = N - L + 1.

% Jessada Karnjana
% 2015.11.10

N = length(x);
if L > N/2
    L = N-L;
end
K = N-L+1;
X = zeros(L,K);
for i = 1:K
    X(1:L,i) = x(i:L+i-1);
end