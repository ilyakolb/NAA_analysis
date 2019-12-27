function [is_round area] = cell_shaped_segmentation(BW)

%% is_round is logical variable that should exclude dendrites that were segmented (active pixels).
is_round=0;

[B,L] = bwboundaries(BW,'noholes');
if size(B,1)>1
    tmp=B;
    clear B
    for l=1:size(tmp,1)
        num_el(l)=size(tmp{l,1},1);
    end
    ind=find(num_el==max(num_el));
    B{1,1}=tmp{ind,1};
end
    
stats = regionprops(L,'Area','Centroid');

threshold = 0.8;  %1 equals for circle, any other shape will be less than 1

for k = 1:length(B)
    boundary = B{k};% obtain (X,Y) boundary coordinates corresponding to label 'k'
    % compute a simple estimate of the object's perimeter
    delta_sq = diff(boundary).^2;
    perimeter = sum(sqrt(sum(delta_sq,2)));
    % obtain the area calculation corresponding to label 'k'
    area = stats(k).Area;
    % compute the roundness metric
    metric = 4*pi*area/perimeter^2;
    
    %%plotting results
%     metric_string = sprintf('%2.2f',metric);
%     if metric > threshold
%         is_round=1;
% %         centroid = stats(k).Centroid;
% %        h=plot(centroid(1),centroid(2),'ko');
%     end
%     text(boundary(1,2)-35,boundary(1,1)+13,metric_string,'Color','b',...
%         'FontSize',14,'FontWeight','bold');
    
end

%     title(['Metrics closer to 1 indicate that ',...
%     'the object is approximately round']);

is_round=metric;
area=area-perimeter;
% if ((area-size(B{1,1},1))<30)
%     is_round=0;
% end
end