clc
clear
close all

% Decoded From non attack
load ('./Output/Data_Output/DecodedPictures/databit_no_attack.mat')

% Decoded From original
%load ('imageBinaryABC.mat')

% imageBinary is size 392x1 reshape to 14x28
imageArray=reshape(imageBinary,[14,28]);
imshow(imageArray)