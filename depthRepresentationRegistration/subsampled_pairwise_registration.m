function [Dx,Dy,py,px,py0,px0]=pairwise_reg(H,subsampling,resolution,robust_lambda)
% decentralized registration
% Input:  H             - (T x 1) cell   -  input image/histogram representation of data
%         resolution    - 1x1 scalar     -  the subpixel resolution i.e. resolution = 100 --> 1/100th of pixel resolution
%         robust_lambda - 1x1 scalar     -  the trend filtering penalty for estimating the global displacement
% Output: Dx,Dy         - (T x T) matrix -  pairwise displacement matrix along the x and y directions
%         py,px         - (T x 1) vector -  trend filtered global displacement estimates along the x and y directions
%         py0,px0       - (T x 1) vector -  u global displacement estimates along the x and y directions

if nargin<2
    % default parameters
    subsampling=1;
    resolution = 100;
    robust_lambda = 0.1;
end

if nargin<3
    resolution = 100;
    robust_lambda = 1;
end

t=0;

tic;
Dx=nan(length(H),length(H));
Dy=nan(length(H),length(H));
S=generate_random_tree(length(H),subsampling); S=or(S,S'); %% pre-allocate which subsampled registrations to perform -- if there are all zero rows, likely to kick an error
num_reg=sum(S(:));
for i=1:length(H)
    for j=i:length(H)
        if S(i,j)==1
            [output, ~] = dftregistration(fft2(H{i}),fft2(H{j}),resolution); %% Code from Manuel Guizar-Sicairos
            xoffSet=output(4);
            yoffSet=output(3);
            Dx(i,j)=xoffSet;
            Dy(i,j)=yoffSet;
            Dx(j,i)=-Dx(i,j);
            Dy(j,i)=-Dy(i,j);
            
            t=t+1;
            clc
            fprintf(['Decentralized registration (' num2str(t) '/' num2str(num_reg) ')...\n']);
            fprintf(['\n' repmat('.',1,50) '\n\n'])
            for tt=1:round(t*50/num_reg)
                fprintf('\b|\n');
            end
            T=toc;
            disp(['Time elapsed (minutes): ' num2str(T/60) ' Time remaining (minutes): ' num2str((num_reg-t)*(T/t)*(1/60))]);
        end
    end
end


disp(['Centralizing the decentralized estimates...']);
[py,py0]=robust_regression(Dy',robust_lambda);
[px,px0]=robust_regression(Dx',robust_lambda);
disp(['Centralizing the decentralized estimates...(Done)']);
end

function [p,p0]=robust_regression(D,lambda)
% robust regression - estimates displacement parameters through outlier
% pruning

D0=D;
S=zeros(size(D));
p0=nanmean(D0-nanmean(D0,2),1);

for t=1:10
    p=nanmean(D-l1tf(nanmean(D,2),lambda),1);
    P=D0-l1tf(nanmean(D,2),lambda);
    S=abs(zscore(P,[],1))>2;S=or(S,S');
    D=D0;
    D(S==1)=nan;
end
end