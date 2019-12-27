function th=kmean1D_threshold(u,factor)

%% initialize threshold
u=u(:);
th=myprctile(u,95);
%mm=mean(u(u<me));
%sd=std(u(u<me));

%th=mm+3*sd;
% define threshold as the averge of two means

for i=1:15
    u1=u(u>th);
    u0=u(u<th);
    if ~isempty(u1)
        mu1=mean(u1);
        mu0=mean(u0);
        th=(mu1*factor+mu0*(1-factor));
    end
end


