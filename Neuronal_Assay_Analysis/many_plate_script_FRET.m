week_result='Z:\GECI Pipeline\Imaging Data\20111012\result_FRET';
mkdir(week_result);
folder_name={ ...
    'Z:\GECI Pipeline\Imaging Data\20111012\P6a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P7a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P8a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P9a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P10a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P11a-20110926\'...
    'Z:\GECI Pipeline\Imaging Data\20111012\P12a-20110926\'};
    
%% process individual folder
for i=6:length(folder_name)
%     NAA_organize_files(folder_name{i});
    NAA_process_dir([folder_name{i},'\imaging'],'FRET');
    cd([folder_name{i},'\imaging\']);
    NAA_pile_results([folder_name{i},'\imaging']);
    cd([folder_name{i},'\imaging\results']);
    NAA_pile_dr_r_FRET;
    NAA_pile_CFP_FRET;
    NAA_pile_YFP_FRET;
    NAA_display_PlateFRET;
end

%% pile results of the week
for i=1:length(folder_name)
    str1=['copy "',folder_name{i},'\imaging\results\*.mat" "',week_result,'"'];
    str2=['copy "',folder_name{i},'\imaging\results\*.ppt" "',week_result,'"'];
    system(str1);
    system(str2);
end
cd(week_result);
    NAA_pile_dr_r_FRET;
    NAA_pile_CFP_FRET;
    NAA_pile_YFP_FRET;