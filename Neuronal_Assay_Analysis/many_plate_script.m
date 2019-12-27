week_result='Z:\GECI Pipeline\Imaging Data\20111018\result_GCaMP';
mkdir(week_result);
folder_name={ ...
    'Z:\GECI Pipeline\Imaging Data\20111018\P1a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P2a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P3a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P4a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P5a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P6a-20111003\'...
    'Z:\GECI Pipeline\Imaging Data\20111018\P7a-20111003\'};

    
%% process individual folder
for i=5:length(folder_name)
    NAA_organize_files(folder_name{i});
    NAA_process_dir([folder_name{i},'\imaging'],'GCaMP');
%     NAA_process_dir([folder_name{i},'\imaging'],'Dye');
    cd([folder_name{i},'\imaging\']);
    NAA_pile_results([folder_name{i},'\imaging']);
    cd([folder_name{i},'\imaging\results']);
    NAA_pile_df_f;
    NAA_display_Plate;
end

%% pile results of the week
for i=1:length(folder_name)
    str1=['copy "',folder_name{i},'\imaging\results\*.mat" "',week_result,'"'];
    str2=['copy "',folder_name{i},'\imaging\results\*.ppt" "',week_result,'"'];
    system(str1);
    system(str2);
end
cd(week_result);
NAA_pile_df_f;