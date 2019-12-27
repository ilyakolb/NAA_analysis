function bg_detail=bg_est(data,plot_flag)
    m=mean(data,2);
    y=data-repmat(m,[1,size(data,2)]);
    [U,S,V]=svds(y,1);
    if sum(U(:,1))>0
        f=V(:,1);
        u=U(:,1)*S(1,1);
    else
        f=-V(:,1);
        u=-U(:,1)*S(1,1);
    end 
    res=y-u*f';
    sigma_u=sqrt(var(res(:)));
    sigma_m=sigma_u/sqrt(length(f));
    
    subset_len=round(length(u)*0.6);
    coef=[];
    for i=1:8
        ind=randperm(length(u));
        ind=ind(1:subset_len); %index of a random pixel subset
        coef=[coef,fewestfit(u(ind),m(ind),sigma_u,sigma_m,0)];
    end
    f_offset=mean(coef(2,:));
    f_offset_std=std(coef(2,:));
    [coef,selmap]=fewestfit(u,m,sigma_u,sigma_m,plot_flag);
    
    bg_detail.f=f+f_offset;
    bg_detail.f_error=f_offset_std;
    bg_detail.u=u;
    bg_detail.SNR=sum(u.^2)*sum(f.^2)/sum(res(:).^2);
    bg_detail.selmap=selmap;
    bg_detail.bgmap=m-coef(2)*u;
    bg_detail.sigma_n=std(res(:));
    if plot_flag==1
        %reconstruction and residule
        
        [uu,ind]=sort(u);
        
        inc=round(length(u)/20);
        ind2=inc:inc:length(u);
%         figure
%         subplot(1,3,1);
%         plot(bg_detail.f*sort(u(ind)'));
%         set(gca,'xlim',[0,length(f)]);
%         subplot(1,3,2);
%         plot(data(ind,:)');
%         set(gca,'xlim',[0,length(f)]);
%         subplot(1,3,3);
%         plot(data(ind,:)'-bg_detail.f*u(ind)'-ones(size(f))*bg_detail.bgmap(ind)');
%         set(gca,'xlim',[0,length(f)]);

%         figure        
%         rainbow_plot(bg_detail.f*u(ind(ind2))');
%         set(gca,'xlim',[0,length(f)]);
% 
%         figure
%         rainbow_plot(data(ind(ind2),:)');
%         set(gca,'xlim',[0,length(f)]);
% 
%         figure;
%         rainbow_plot(data(ind(ind2),:)'-bg_detail.f*u(ind(ind2))');
%         set(gca,'xlim',[0,length(f)]);
%         
    
    end