function NAA_pile_df_f(type, sub_type)
% Create the results files (text and Excel).
if (strcmp(type,'GCaMP96b-ERtag'))
    type='GCaMP96b'; %patch for analysis GCaMP data without red channel, Hod 20141001
end

% Make sure the Apache POI Java files are enabled so we can create the .xlsx file.
enablePOI();
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.*;

if strcmpi(type, 'RCaMP96b')||strcmpi(type, 'RCaMP96c')||strcmpi(type, 'RCaMP96z')||strcmpi(type, 'RCaMP96u')||strcmpi(type, 'RCaMP96uf')
    xlstitle = {'Plate', 'Well', 'Construct', '# ROI', 'GFP', 'F0', 'Fmax', 'norm F0'};
    txttitle = {'replicate_plate', 'well', 'construct', 'roi', 'gfp', 'f0', 'fmax', 'norm_f0'};
else
    xlstitle = {'Plate', 'Well', 'Construct', '# ROI', 'mCherry', 'F0', 'Fmax', 'norm F0'};
    txttitle = {'replicate_plate', 'well', 'construct', 'roi', 'mcherry', 'f0', 'fmax', 'norm_f0'};
end

if strcmpi(type, 'GCaMP96') || strcmpi(type, 'GCaMP96b') ||strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b') ||...
        strcmpi(type, 'OGB1')|| strcmpi(type, 'GCaMP96z')||strcmpi(type, 'RCaMP96z')||strcmpi(type, 'GCaMP96bf')...
        ||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf')||strcmpi(type, 'GCaMP96u')||strcmpi(type, 'RCaMP96u')
    nAP = [1, 3, 10, 160];
    response = 'f';
    file_suffix = '';
elseif strcmpi(type, 'mngGECO')
    nAP = [1, 2, 3, 5, 10, 20, 40, 160];
    response = 'f';
    file_suffix = '';
elseif strcmpi(type, 'GCaMP')|| strcmpi(type, 'RCaMP96c')|| strcmpi(type, 'GCaMP96c')|| strcmpi(type, 'GCaMP96d')
    nAP = [1, 2, 3, 5, 10, 20, 40, 80, 160];
    response = 'f';
    file_suffix = '';
elseif strcmpi(type, 'FRET96')
    nAP = [1, 3, 10, 160];
    response = 'r';
    if nargin == 1
        file_suffix = '';
    else
        file_suffix = sub_type;
    end
elseif strcmpi(type, 'FRET')
    nAP = [1, 2, 3, 5, 10, 20, 40, 80, 160];
    response = 'r';
    if nargin == 1
        file_suffix = '';
    else
        file_suffix = sub_type;
    end
else
    error('Unknown protocol: %s', type);
end

% Add a response column for each pulse.
for ap = nAP
    xlstitle = [xlstitle, {['d' response response '(' num2str(ap) 'AP)']}]; %#ok<AGROW>
    txttitle = [txttitle, {['d' response response '_' num2str(ap) '_ap']}]; %#ok<AGROW>
end
xlstitle = [xlstitle, {['d' response response '(max)']}];
txttitle = [txttitle, {['d' response response '_max']}];

% Include a blank column after the responses.
blank_col_ind = length(xlstitle);

if strcmpi(type, 'GCaMP96') || strcmpi(type, 'GCaMP96b') ||strcmpi(type, 'RCaMP96') || strcmpi(type, 'OGB1')||...
        strcmpi(type, 'GCaMP')|| strcmpi(type, 'GCaMP96z')||strcmpi(type, 'RCaMP96z')|| strcmpi(type, 'GCaMP96bf')...
        ||strcmpi(type, 'GCaMP96uf')|| strcmpi(type, 'mngGECO') ||strcmpi(type, 'RCaMP96uf')||strcmpi(type, 'GCaMP96u')||strcmpi(type, 'RCaMP96u')
    xlstitle = [xlstitle {'ES50', 'DT1/2(10AP)', 'RT1/2(10AP)', 'tpeak(10AP)', 'DT1/2(160AP)', 'T1', 'T2'}];
    txttitle = [txttitle {'es50', 'dt1_2_10_ap', 'rt1_2_10_ap', 'tpeak_10_ap', 'dt1_2_160_ap', 't1', 't2'}];
elseif strcmpi(type, 'GCaMP96c') || strcmpi(type, 'GCaMP96d')
    xlstitle = [xlstitle {'ES50', 'DT1/2(10AP)', 'RT1/2(10AP)', 'tpeak(10AP)', 'DT1/2(160AP)', 'T1', 'T2'}];
    txttitle = [txttitle {'es50', 'dt1_2_10_ap', 'rt1_2_10_ap', 'tpeak_10_ap', 'dt1_2_160_ap', 't1', 't2'}];
elseif strcmpi(type, 'RCaMP96b')|| strcmpi(type, 'RCaMP96c')
    xlstitle = [xlstitle {'ES50', 'DT1/2(10AP)', 'RT1/2(10AP)', 'tpeak(10AP)', 'DT1/2(160AP)', 'T1', 'T2','Fraction Bleach','dff(PSW)','dff(PSW_B2B)'}];
    txttitle = [txttitle {'es50', 'dt1_2_10_ap', 'rt1_2_10_ap', 'tpeak_10_ap', 'dt1_2_160_ap', 't1', 't2','fraction_bleach','dff_psw','dff_psw_b2b'}];
elseif strcmpi(type, 'FRET96')
    xlstitle = [xlstitle {'ES50', 'DT1/2(10AP)', 'RT1/2(10AP)', 'tpeak(10AP)', 'DT1/2(160AP)', 'T1', 'T2','SNR_1AP','SNR_3AP','SNR_10AP','SNR_160AP','SNR_1AP_SEM','SNR_3AP_SEM','SNR_10AP_SEM','SNR_160AP_SEM'}];
    txttitle = [txttitle {'es50', 'dt1_2_10_ap', 'rt1_2_10_ap', 'tpeak_10_ap', 'dt1_2_160_ap', 't1', 't2','snr_1ap','snr_3ap','snr_10ap','snr_160ap','snr_1ap_sem','snr_3ap_sem','snr_10ap_sem','snr_160ap_sem'}];
end
column_count = length(xlstitle);

% Make sure the headers for the text file are only made of lowercase letters, numbers and underscores.
invalidTextHeaders = regexp(txttitle, '[^a-z0-9_]', 'start', 'once');
if ~isempty(cell2mat(invalidTextHeaders))
    ind = cellfun(@(x) ~isempty(x), invalidTextHeaders);
    invalidTextHeaders = txttitle(ind);
    error('Invalid headers for TXT results file: %s', strjoin(invalidTextHeaders, ', '));
end

M = xlstitle;

files = dir('*Summary.mat');

if isempty(files)
    error('No summary files could be found');
end

data_size = 0;
for i=1:length(files);
    if strcmpi(type, 'FRET') || strcmpi(type, 'FRET96')
        if nargin == 1
            para_field = 'para_arrayRatio';
            summary_field = 'summaryRatio';
            minROI = 1;
        elseif strcmp(sub_type, 'CFP')
            para_field = 'para_arrayCFP';
            summary_field = 'summaryCFP';
            minROI = 2;
        elseif strcmp(sub_type, 'YFP')
            para_field = 'para_arrayYFP';
            summary_field = 'summaryYFP';
            minROI = 2;
        end
    else
        para_field = 'para_array';
        summary_field = 'summary';
        minROI = 0;
    end
    if strcmp(type,'RCaMP96b')||strcmpi(type, 'RCaMP96c')
        load(files(i).name, para_field, summary_field, 'cell_list', 'temperature1', 'temperature2', 'fmax', 'bleach', 'med_psw', 'med_psw_b2b');
    elseif strcmp(type,'FRET96')
        load(files(i).name, para_field, summary_field, 'cell_list', 'temperature1', 'temperature2', 'fmax','SNR','SNR_STD');
    else
        load(files(i).name, para_field, summary_field, 'cell_list', 'temperature1', 'temperature2', 'fmax');
    end
    para_array = eval(para_field);
    summary = eval(summary_field);
    
    info = NAA_file_info(files(i).name);
    plate = info.plate;
    well = regexp(info.well, '-', 'split');
    well = well{2};
    if length(well) == 2
        % Zero-pad the well number so it always has two digits.
        well = [well(1) '0' well(2)];
    end
    construct = info.construct;
    nROI=length(cell_list);
    if nROI >= minROI
        % Remove NaN values and put 0 instead
        if sum(isnan(summary.df_fpeak_med))
            summary.df_fpeak_med = zeros(size(summary.df_fpeak_med));
        end
        
        ES50=NAA_get_es50(summary.df_fpeak_med,nAP);
        
        f0=[para_array(2,:).f0];
        
        if ~exist('fmax', 'var')
            fmax=zeros(size(cell_list));
            dff_max=zeros(size(cell_list));
        else
            if ~isempty(fmax)
                dff_max=(fmax-f0)./f0;
            else
                fmax=zeros(size(cell_list));
                dff_max=zeros(size(cell_list));
            end
        end
        
        if strcmpi(type, 'GCaMP96') || strcmpi(type, 'GCaMP96b') ||strcmpi(type, 'RCaMP96') || strcmpi(type, 'OGB1')|| strcmpi(type, 'GCaMP96z')||strcmpi(type, 'RCaMP96z')|| strcmpi(type, 'GCaMP96bf')||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'RCaMP96uf')||strcmpi(type, 'GCaMP96u')||strcmpi(type, 'RCaMP96u')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1)};
        elseif strcmpi(type, 'mngGECO')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1)};
        elseif strcmpi(type, 'FRET96')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1),SNR(1),SNR(2),SNR(3),SNR(4),SNR_STD(1),SNR_STD(2),SNR_STD(3),SNR_STD(4)};
        elseif strcmpi(type, 'RCaMP96b')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1),bleach,med_psw,med_psw_b2b};
        elseif strcmpi(type, 'RCaMP96c')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),summary.df_fpeak_med(9),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1),bleach,med_psw,med_psw_b2b};
        elseif strcmpi(type, 'GCaMP96c')|| strcmpi(type, 'GCaMP96d')
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),summary.df_fpeak_med(9),median(dff_max),ES50,summary.decay_half_med(3),summary.rise_half_med(3),summary.timetopeak_med(3),summary.decay_half_med(4),temperature1(1),temperature2(1)};
        else
            entry={plate,well,construct,nROI,mean([cell_list.mCherry]),summary.f0(2),median(fmax),summary.f0(2)/mean([cell_list.mCherry]),summary.df_fpeak_med(1),summary.df_fpeak_med(2),summary.df_fpeak_med(3),summary.df_fpeak_med(4),summary.df_fpeak_med(5),summary.df_fpeak_med(6),summary.df_fpeak_med(7),summary.df_fpeak_med(8),summary.df_fpeak_med(9),median(dff_max),ES50,summary.decay_half_med(5),summary.rise_half_med(5),summary.timetopeak_med(5),summary.decay_half_med(9),temperature1(1),temperature2(1)};
        end
        for j = 1:length(entry)
            if ~isempty(entry{j}) && ~ischar(entry{j}) && isnan(entry{j})
                entry{j} = [];
            end
        end
        M=[M;entry];
        data_size=data_size+1;
    end
    clear fmax;
end

txtFilename = ['NAA_result_', plate, file_suffix, '.txt'];
xlsxFilename = ['NAA_result_', plate, file_suffix, '.xlsx'];
if exist(xlsxFilename, 'file')
    disp('Results files already exist -- not writing xlsx file.');
else
    fid = fopen(txtFilename, 'w');
    wb = org.apache.poi.xssf.usermodel.XSSFWorkbook();
    wellSheet = wb.createSheet('Wells');
    wellSheet.createFreezePane(3, 1);
    constructSheet = wb.createSheet('Constructs');
    constructSheet.createFreezePane(1, 1);
    
    % Add the header row to the text file.
    if strcmpi(type, 'GCaMP96') || strcmpi(type, 'GCaMP96b') ||strcmpi(type, 'RCaMP96') || strcmpi(type, 'OGB1')|| strcmpi(type, 'GCaMP96z')||strcmpi(type, 'RCaMP96z')|| strcmpi(type, 'GCaMP96bf')...
            ||strcmpi(type, 'GCaMP96uf')||strcmpi(type, 'mngGECO')||strcmpi(type, 'RCaMP96uf')||strcmpi(type, 'GCaMP96u')||strcmpi(type, 'RCaMP96u')
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', txttitle{:});
    elseif strcmpi(type, 'RCaMP96b')
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', txttitle{:});
    elseif strcmpi(type, 'RCaMP96c')
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', txttitle{:});
    elseif strcmpi(type, 'FRET96')
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', txttitle{:});
    else
        fprintf(fid, '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n', txttitle{:});
    end
    
    % Add the header rows to the xlsx sheets.
    headerStyle = wb.createCellStyle();
    headerStyle.setAlignment(CellStyle.ALIGN_CENTER);
    font = wb.createFont();
    font.setBoldweight(Font.BOLDWEIGHT_BOLD);
    headerStyle.setFont(font);
    headerRow = wellSheet.createRow(0);
    for i = 1:length(xlstitle)
        if i <= blank_col_ind
            cell = headerRow.createCell(i - 1);
        else
            cell = headerRow.createCell(i);
        end
        cell.setCellStyle(headerStyle);
        cell.setCellValue(xlstitle{i});
    end
    headerRow = constructSheet.createRow(0);
    cell = headerRow.createCell(0);
    cell.setCellStyle(headerStyle);
    cell.setCellValue('Construct');
    cell = headerRow.createCell(1);
    cell.setCellStyle(headerStyle);
    cell.setCellValue('# Replicates');
    for i = 4:length(xlstitle)    % skip the plate and well columns
        if i <= blank_col_ind
            cell = headerRow.createCell(i - 2);
        else
            cell = headerRow.createCell(i - 1);
        end
        cell.setCellStyle(headerStyle);
        cell.setCellValue(xlstitle{i});
    end
    
    rowNum = 1;
    try
        % Group data by construct.
        construct=unique({M{2:end,3}});
        M1=M;
        M=M1(1,:);
        for i=1:length(construct)
            ind=strcmp({M1{1:(data_size+1),3}},construct{i});
            M=[M;M1(ind,:)];
            ind2 = find(ind);
            for j = 1:length(ind2)
                % Add the data to the text file.
                fprintf(fid, '%s\t%s\t%s\t%d\t', M1{ind2(j), 1:4});
                fprintf(fid, '%.12g\t', M1{ind2(j), 5:blank_col_ind});
                fprintf(fid, '%.12g\t', M1{ind2(j), (blank_col_ind + 1):end-1});
                fprintf(fid, '%.12g\n', M1{ind2(j), end});
                
                % Add the data to the xlsx file.
                row = wellSheet.createRow(rowNum);
                for k = 1:size(M1, 2)
                    if k <= blank_col_ind
                        cell = row.createCell(k - 1);
                    else
                        cell = row.createCell(k);
                    end
                    
                    % ilya added 5/9/19: if blank entry, put in 0
                    if isempty(M1{ind2(j), k})
                        cell.setCellValue(0);
                    else
                        cell.setCellValue(M1{ind2(j), k});
                    end
                    
                    % TODO: any benefit to coloring/formatting any of the data?
                    % import org.apache.poi.ss.usermodel.CellStyle;
                    % import org.apache.poi.ss.usermodel.IndexedColors;
                    % style = wb.createCellStyle();
                    % style.setAlignment(CellStyle.ALIGN_RIGHT)
                    % style.setFillBackgroundColor(IndexedColors.RED.getIndex())
                    % cell.setCellStyle(style);
                end
                
                rowNum = rowNum + 1;
            end
        end
        for i = 1:length(xlstitle)
            wellSheet.autoSizeColumn(i - 1);
        end
        
        % The text file only has the well-level content.
        fclose(fid);
        fid = [];
        
        % Populate the construct sheet with the medians and std. errors.
        for i=1:length(construct)
            ind=strcmp({M{1:(data_size+1),3}},construct{i});
            row = constructSheet.createRow(i);
            row.createCell(0).setCellValue(construct{i});
            row.createCell(1).setCellValue(length(find(ind)));
            stdErrRow = constructSheet.createRow(length(construct) + 1 + i);
            stdErrRow.createCell(0).setCellValue([construct{i} '_SEM']);
            stdErrRow.createCell(1).setCellValue(length(find(ind)));
            for j=4:column_count
                if j <= blank_col_ind
                    cell = row.createCell(j - 2);
                    stdErrCell = stdErrRow.createCell(j - 2);
                else
                    cell = row.createCell(j - 1);
                    stdErrCell = stdErrRow.createCell(j - 1);
                end
                
                % Show the median and std. error values.
                med = median([M{ind,j}]);
                cell.setCellValue(med);
                std_err = std([M{ind,j}])/sqrt(length(ind));
                stdErrCell.setCellValue(std_err);
            end
        end
        for i = 3:length(xlstitle)
            constructSheet.autoSizeColumn(i - 3);
        end
    catch ME
        if ~isempty(fid)
            fclose(fid);
        end
        rethrow(ME);
    end
    
    % Save the xlsx content.
    fileStream = java.io.FileOutputStream(xlsxFilename);
    wb.write(fileStream);
    fileStream.close();
end
end
