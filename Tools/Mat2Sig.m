function x = Mat2Sig(X,N,L)

% This function will convert the matrix X to
% a signal x of lenght N, given the window lenght L.

% Jessada Karnjana
% 2015.11.10

if L > N/2
    L = N-L;
end
K = N-L+1;
x = zeros(N,1);
Lp = min(L,K);
Kp = max(L,K);
for k = 0:Lp-2
    for m = 1:k+1
        x(k+1) = x(k+1)+(1/(k+1))*X(m,k-m+2);
    end
end
for k = Lp-1:Kp-1
     for m = 1:Lp;
        x(k+1) = x(k+1)+(1/(Lp))*X(m,k-m+2);
     end
end
for k = Kp:N
     for m = k-Kp+2:N-Kp+1;
       x(k+1) = x(k+1)+(1/(N-k))*X(m,k-m+2);
     end
end