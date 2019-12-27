function [r,selmap]=fewestfit(u,m,sigma_u,sigma_m,plot_flag) 
%u: x
%m: y

flag=1;
selmap=true(size(u));
pixelno=0;

while flag==1
    xx=[ones(size(u(selmap))),u(selmap)];
    r=xx\m(selmap);
    err=m-(u+4*sigma_u)*r(2)-r(1);
    [s_err,I]=sort(err,'descend');    
    if (s_err(pixelno+1)>4*sigma_m) & sum(selmap)>1
        pixelno=pixelno+1;
        selmap=true(size(u));
        selmap(I(1:pixelno))=0;     
    else
        flag=0;
    end        
end

if plot_flag==1
x=[ones(sum(selmap),1),u(selmap)];
y=m(selmap);
[b,bint] = regress(y,x);
figure
eplot([u(selmap),3*sigma_u*ones(sum(selmap),1)],[m(selmap),3*sigma_m*ones(sum(selmap),1)],'b');
hold on;
plot(u,u*r(2)+r(1),'k');
plot(u(~selmap),m(~selmap),'.r');
end
%set_paperfig;
