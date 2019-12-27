function f=rainbow_plot(y)
map=jet(256);
% map=map(33:224,:);
col=size(y,2);
hold on;
for i=1:size(y,2)
    plot(y(:,i),'color',map(round(i/col*255),:))
end