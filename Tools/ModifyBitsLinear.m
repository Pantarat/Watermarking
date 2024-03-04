function X = ModifyBitsLinear(matrix,i1,i2,wmbit)

% SVD
[U,D,V] = svd(matrix);
DModi = D;
%Linear
y1 = D(i1,i1);
y2 = D(i2,i2);
x1 = i1;
x2 = i2;
m = (y2-y1)/(x2-x1);
%Y=((y2-y1)/(x2-x1))*(x-x1);
% modify D matrix from i1,i1 to i2,i2
    for k = i1:i2
        if (wmbit == 1)
            x = k;
            DModi(k,k) = m*(x-x1)+y1;
        end
        if (wmbit == 0)
            DModi(k,k) = D(i2,i2);
        end
    end

    X = U*DModi*V';
end