function overlay=NAA_create_overlay(Green,Red)
    ss=size(Red);
    overlay=zeros([ss,3]);
    
    MM=myprctile(Red,99.7);
    mm=myprctile(Red,10);
    % MM=800;
    % mm=200;
    overlay(:,:,1)=(Red-mm)/(MM-mm);
    
    % MM=500;
    % mm=100;
    MM=myprctile(Green,99.7);
    mm=myprctile(Green,10);
    overlay(:,:,2)=(Green-mm)/(MM-mm);
    
    overlay(overlay>1)=1;
    overlay(overlay<0)=0;
end