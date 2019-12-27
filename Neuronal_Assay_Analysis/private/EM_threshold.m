%fit data by gaussian mixture model using expectation maximization
function th=EM_threshold(observation,init_prctile,n)


n_iteration=20;
n_component=2;

if nargin<2
    init_prctile=80;
end

th0=prctile(observation,init_prctile);
sigma_init=[std(observation(observation<th0)),std(observation(observation>th0))];
mu_init=[mean(observation(observation<th0)),mean(observation(observation>th0))];
a_init=[init_prctile,100-init_prctile]/100;

expectation=zeros(length(observation),n_component);
for i=1:n_iteration
    for j=1:n_component
        expectation(:,j)=a_init(j)*exp(-(observation-mu_init(j)).^2/2/sigma_init(j)^2)/sigma_init(j);
    end
    
    for j=1:length(observation)
        expectation(j,:)=expectation(j,:)/sum(expectation(j,:));
    end
    
    for j=1:n_component
        mu_init(j)=sum(expectation(:,j).*observation)./sum(expectation(:,j));
        a_init(j)=mean(expectation(:,j));
        sigma_init(j)=sum(expectation(:,j).*(observation-mu_init(j)).^2)/sum(expectation(:,j));
        sigma_init(j)=sqrt(sigma_init(j));  
    end
    if sigma_init(2)==0
        sigma_init(2)=sigma_init(1);
    end
    
    a_init=a_init/sum(a_init);
end

if nargin<3
    th=fzero(@diff_pdf,mu_init(1)+sigma_init(1)*3);
else
    th=mu_init(1)+sigma_init(1)*n;
end

%%
% figure
% [h,xout]=hist(observation,50);
% h=h/sum(h);
% bar(xout,h)
% pdf=normpdf(xout,mu_init(1),sigma_init(1))*a_init(1)+normpdf(xout,mu_init(2),sigma_init(2))*a_init(2);
% hold
% plot(xout,pdf/sum(pdf));


function x=diff_pdf(in)
    x=normpdf(in,mu_init(1),sigma_init(1))-normpdf(in,mu_init(2),sigma_init(2));
end

end