week_result='Z:\GECI Pipeline\Imaging Data\20111004\result_GCaMP96';
mkdir(week_result);
folder_name={ ...
    'Z:\GECI Pipeline\Imaging Data\20111004\P1a-20110913\'};
    
%% process individual folder
for i=1:length(folder_name)
%     NAA_organize_files96(folder_name{i});
    NAA_process_dir([folder_name{i},'\imaging'],'GCaMP96');
    cd([folder_name{i},'\imaging\']);
    NAA_pile_results([folder_name{i},'\imaging']);
    cd([folder_name{i},'\imaging\results']);
    NAA_pile_df_f96;
    NAA_display_Plate96;
end

%% pile results of the week
for i=1:length(folder_name)
    str1=['copy "',folder_name{i},'\imaging\results\*.mat" "',week_result,'"'];
    str2=['copy "',folder_name{i},'\imaging\results\*.ppt" "',week_result,'"'];
    system(str1);
    system(str2);
end
cd(week_result);
NAA_pile_df_f96;