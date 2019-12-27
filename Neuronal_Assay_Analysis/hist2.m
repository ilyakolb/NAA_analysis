function hist2(x,y,n)


% m1=min(x);
% M1=max(x);
% m2=min(y);
% M2=max(y);
m1=0;
M1=400;
m2=0;
M2=400;
map=zeros(n,n);

bin1=(M1-m1)/n;
bin2=(M2-m2)/n;
for i=1:n
    for j=1:n
       map(j,i)=sum((x>(m1+(i-1)*bin1))&(x<(m1+(i)*bin1))&(y>(m2+(j-1)*bin2))&(y<(m2+j*bin2)));
    end
end
%%
figure;imagesc(map,'XData',[m1,M1],'YData',[m2,M2]);axis xy;
