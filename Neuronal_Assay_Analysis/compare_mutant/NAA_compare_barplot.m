function NAA_compare_barplot(mutant_data,control_data,field,nstim)

% field='df_fpeak_med';
% % field='df_fpeak_med';
% % field='decay_half_med';
% nstim=1;



%mutant_data=mutant_data_norm;
datenumber=datenum({mutant_data.date},'yyyymmdd');
[token, remain] = strtok({mutant_data.construct},'dot');
construct_num=str2double(strtok(remain,'dot'));

sort_num=construct_num'*10^6+datenumber;
% sort_num=construct_num'+datenumber*10^6;

[S,ind]=sort(sort_num);
mutant_data=mutant_data(ind);
control_data=control_data(ind);

figure;hold on;

data_med=[];
for i=1:length(ind)
    data=mutant_data(i).(field);    
    data_med=[data_med;median(data(nstim,:),2)'];            
end
hbars=bar(1:length(ind),data_med);
colormap(summer);
top=double(max(data_med(:)));

for i=1:length(ind)
    data=mutant_data(i).(field);
    control=control_data(i).(field);
    for j=1:length(nstim)
        x =get(get(hbars(j),'children'), 'xdata');
        x = mean(x([1,3],i));
        
        plot(x,data(nstim(j),:),'og','MarkerSize',2);
%         plot(x,control(nstim(j),:),'xk','MarkerSize',4);
        [p,h]=ranksum(data(nstim(j),:),control(nstim(j),:));
%         [h,p]=ttest2(data(nstim(j),:),control(nstim(j),:));
        if p<0.001
              text(x,top*1.2,'***','color','r','HorizontalAlignment','center');
        elseif p<0.01
%             text(x,top*1.1,{'*','*'},'color','r', 'interpreter','latex');
              text(x,top*1.2,'**','color','r', 'HorizontalAlignment','center');
        elseif p<0.05
            text(x,top*1.2,'*','color','r','HorizontalAlignment','center');
        end
%         text(x,top*1.32,['p=',num2str(p,'%0.3f')],'HorizontalAlignment','center');%,'rotation',90)
    end
end
ylim([0,top*1.4]);

set(gca,'XTick',1:length(ind));
label={};
for i=1:length(ind)
    label{i}={mutant_data(i).construct,mutant_data(i).date};
end
my_xticklabels(gca,1:length(ind),label);

% my_xticklabels(gca,1:length(ind),label, 'Rotation',90,'HorizontalAlignment','right')
% set(gca,'XTickLabel',{mutant_data.construct});    