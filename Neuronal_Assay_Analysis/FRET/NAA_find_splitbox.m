function [topbox,botbox,width,height]=NAA_find_splitbox(avg)

debug = false;
    
bg_scale = 1.6;
frame_th = 60;
min_frame = 5;

%% Find pixels of the frame based on the average intensity of the outer ring.
bg = (median(avg(:, 1)) + median(avg(:, end)) + median(avg(1, :)) + median(avg(end, :))) / 4;
frame=avg<(bg * bg_scale);
profile_x=sum(frame,1);
profile_y=sum(frame,2);
if debug
    figure;subplot(2,2,1:2);imagesc(avg);colorbar;subplot(2,2,3);plot(profile_x,'.-');subplot(2,2,4);plot(profile_y,'.-')
end

a=find((profile_x(1:100)<frame_th));
if isempty(a)
    a(1) = min_frame;
end
b=find((profile_x(450:end)>frame_th));
if isempty(b)
    b(1) = 512 - min_frame;
end

xlimit=[a(1),b(1)+449];

a=find((profile_y(1:100)<frame_th));
if isempty(a)
    a(1) = min_frame;
end
b=find((profile_y(196:316)>frame_th));
toplimit=[a(1),b(1)+195];
a=find((profile_y(toplimit(2):316)<frame_th));
b=find((profile_y(450:end)>frame_th));
if isempty(b)
    b(1) = 512 - min_frame;
end
botlimit=[a(1)+toplimit(2)-1,b(1)+450-1];

%%

width=485;
height=230;

centerTop=[(toplimit(1)+toplimit(2))/2,(xlimit(1)+xlimit(2))/2];
topbox=int16([max(min_frame, centerTop(2)-width/2),max(min_frame, centerTop(1)-height/2),width,height]); %x,y,w,h


%%
centerbot=[(botlimit(1)+botlimit(2))/2,(xlimit(1)+xlimit(2))/2];
if debug
    botbox=int16([max(min_frame, centerbot(2)-width/2),max(min_frame, centerbot(1)-height/2),width,height]); %x,y,w,h
    subplot(2,2,1:2); hold on;
    rectangle('position',topbox,'EdgeColor','r');
    rectangle('position',botbox,'EdgeColor','r');
end

%%
rangex=-5:5;
rangey=-4:4;

imTop=avg(topbox(2):(topbox(2)+height-1),topbox(1):(topbox(1)+width-1));
normTop=imTop(:)-mean(imTop(:));
normTop=normTop/norm(normTop);
for i=1:length(rangex)
    for j=1:length(rangey)
        centerBot_try=[centerbot(1)+rangey(j),centerbot(2)+rangex(i)];
        botbox=int16([max(min_frame, centerBot_try(2)-width/2), max(min_frame, centerBot_try(1)-height/2),width,height]); %x,y,w,h
        imBot=avg(botbox(2):(botbox(2)+height-1),botbox(1):(botbox(1)+width-1));
        normBot=imBot(:)-mean(imBot(:));
        normBot=normBot/norm(normBot);
        xcorrvalue(i,j)=normTop'*normBot;
    end
end    
[~,idx]=max(xcorrvalue(:));
[i,j]=ind2sub(size(xcorrvalue),idx);
centerBot_try=[centerbot(1)+rangey(j),centerbot(2)+rangex(i)];

botbox=int16([max(min_frame, centerBot_try(2)-width/2), max(min_frame, centerBot_try(1)-height/2), width, height]); %x,y,w,h

if debug
    imBot=avg(botbox(2):(botbox(2)+height-1),botbox(1):(botbox(1)+width-1));
    normBot=imBot(:)-mean(imBot(:));
    normBot=normBot/norm(normBot);
    rectangle('position',botbox,'EdgeColor','w');
    text(centerBot_try(2), centerBot_try(1), num2str(normTop'*normBot), 'BackgroundColor', 'white');
end
