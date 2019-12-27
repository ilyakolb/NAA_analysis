function df_f=rawf2df_f_minf(f,f0_range)
num_trials=5;
ss=size(f);
% f=reshape(f,ss(1),[]);
% f0=mean(f(f0_range,:));

f=reshape(f,[],num_trials);
df_f=zeros(size(f));

for i=1:num_trials
    f0(i)=myprctile(f(:,i),33);
    df_f(:,i)=(f(:,i)-f0(i))./f0(i);
end
% f0=repmat(f0,[ss(1),1]);
df_f=reshape(df_f,ss);
