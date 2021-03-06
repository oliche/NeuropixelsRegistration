function [Dx,Dy,py,px,cmax]=pairwise_reg(H,subblocks,us)

tmp=linspace(1,size(H{1},2),subblocks+1);
for s=1:subblocks
    blockcoor{s}=round(tmp(s)):round(tmp(s+1)); %#ok<AGROW>
end

t=0;
num_reg=subblocks*length(H)*(length(H)+1)/2;
tic;
Dx=nan(length(H),length(H),subblocks);
Dy=nan(length(H),length(H),subblocks);
for i=1:length(H)
    for j=i:length(H)
        for s=1:subblocks
            
            [output, ~] = dftregistration(fft2(H{i}(:,blockcoor{s})),fft2(H{j}(:,blockcoor{s})),us);
            xoffSet=output(3);
            yoffSet=output(4);
            %             c=normxcorr2(H{i}(:,blockcoor{s}),H{j}(:,blockcoor{s}));
            % %             [ypeak,xpeak] = find(c==max(c(:)));
            %             cmax(i,j,s)=max(c(:));
            %             cmax(j,i,s)=cmax(i,j,s);
            %             yoffSet = ypeak-size(H{i}(:,blockcoor{s}),1);
            %             xoffSet = xpeak-size(H{i}(:,blockcoor{s}),2);
            Dx(i,j,s)=xoffSet;
            Dy(i,j,s)=yoffSet;
            Dx(j,i,s)=-Dx(i,j,s);
            Dy(j,i,s)=-Dy(i,j,s);
            t=t+1;
            clc
            fprintf(['Pairwise registration (' num2str(t) '/' num2str(num_reg) ')...\n']);
            fprintf(['\n' repmat('.',1,50) '\n\n'])
            for tt=1:round(t*50/num_reg)
                fprintf('\b|\n');
            end
            T=toc;
            disp(['Time elapsed (minutes): ' num2str(T/60) ' Time remaining (minutes): ' num2str((num_reg-t)*(T/t)*(1/60))]);
        end
    end
end

cmax=[];

D=mean(Dy,3)';
lambda=1;
D0=D;
S=zeros(size(D));
p0=nanmean(D0-nanmean(D0,2),1);


% robust regression
for t=1:10
    p=nanmean(D-l1tf(nanmean(D,2),lambda),1);
    P=D0-l1tf(nanmean(D,2),lambda);
    S=abs(zscore(P,[],1))>2;S=or(S,S');
    D=D0;
    D(S==1)=nan;
end

py0=p0;
py=p;

D=mean(Dx,3)';
lambda=1;
D0=D;
S=zeros(size(D));
p0=nanmean(D0-nanmean(D0,2),1);


% robust regression
for t=1:10
    p=nanmean(D-l1tf(nanmean(D,2),lambda),1);
    P=D0-l1tf(nanmean(D,2),lambda);
    S=abs(zscore(P,[],1))>2;S=or(S,S');
    D=D0;
    D(S==1)=nan;
end
px0=p0;
px=p;