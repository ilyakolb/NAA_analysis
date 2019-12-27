load('para_array_cherry.mat','para_array');
ss=size(para_array);
df_f=reshape([para_array.df_f],[],ss(1),ss(2));
df_fmean=mean(df_f,3);
df_fpeak=reshape([para_array.df_fpeak],ss);
df_fpeak_mean=mean(df_fpeak,2);
figure;
subplot(1,3,1);
plot(df_fmean(:,1:6));
legend('7mA','15mA','22mA','40mA','58mA','62mA');
subplot(1,3,2);
plot(df_fmean(:,7:10));
legend('20Hz','40Hz','60Hz','80Hz');
subplot(1,3,3);
plot(df_fmean(:,11:15));
legend('100us','200us','300us','500us','1000us');


figure;
subplot(1,3,1)
plot([7,15,22,40,58,62],df_fpeak_mean(1:6),'o-');
subplot(1,3,2)
plot([20,40,60,80],df_fpeak_mean(7:10),'o-');
subplot(1,3,3)
plot([100,200,300,500,1000],df_fpeak_mean(11:15),'o-');

