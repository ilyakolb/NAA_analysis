function convertNAAResults()
    [fileName, dirPath] = uigetfile('*.xls', 'Choose an NAA results file:');
    if fileName == 0
        return
    end
    xlsFilePath = fullfile(dirPath, fileName);
    
    [~, fileName, ~] = fileparts(xlsFilePath);
    [fileName, dirPath] = uiputfile('*.txt', 'Save the new NAA results file:', fullfile(dirPath, [fileName '.txt']));
    if fileName == 0
        return
    end
    txtFilePath = fullfile(dirPath, fileName);
    
    fieldNameMap = containers.Map();
    fieldNameMap('Plate') = 'replicate_plate';
    fieldNameMap('Well') = 'well';
    fieldNameMap('construct') = 'construct';
    fieldNameMap('ROI#') = 'roi';
    fieldNameMap('mCherry') = 'mcherry';
    fieldNameMap('F0') = 'f0';
    fieldNameMap('Fmax') = 'fmax';
    fieldNameMap('norm F0') = 'norm_f0';
    fieldNameMap('dff(1AP)') = 'dff_1_ap';
    fieldNameMap('dff(2AP)') = 'dff_2_ap';
    fieldNameMap('dff(3AP)') = 'dff_3_ap';
    fieldNameMap('dff(5AP)') = 'dff_5_ap';
    fieldNameMap('dff(10AP)') = 'dff_10_ap';
    fieldNameMap('dff(20AP)') = 'dff_20_ap';
    fieldNameMap('dff(40AP)') = 'dff_40_ap';
    fieldNameMap('dff(80AP)') = 'dff_80_ap';
    fieldNameMap('dff(160AP)') = 'dff_160_ap';
    fieldNameMap('dff(max)') = 'dff_max';
    fieldNameMap('ES50') = 'es50';
    fieldNameMap('DT1/2(10AP)') = 'dt1_2_10_ap';
    fieldNameMap('RT1/2(10AP)') = 'rt1_2_10_ap';
    fieldNameMap('tpeak(10AP)') = 'tpeak_10_ap';
    fieldNameMap('DT1/2(160AP)') = 'dt1_2_160_ap';
    fieldNameMap('T1') = 't1';
    fieldNameMap('T2') = 't2';
    
    [~, ~, xlsData] = xlsread(xlsFilePath);
    [rowCount, colCount] = size(xlsData);
    fid = fopen(txtFilePath, 'w');
    for c = 1:colCount
        xlsFieldName = xlsData{1, c};
        if isnan(xlsFieldName)
            % Do nothing, it's a blank column.
        else
            if isKey(fieldNameMap, xlsFieldName)
                txtFieldName = fieldNameMap(xlsFieldName);
            else
                error('Unknown column name: %s', xlsFieldName);
            end
            if c < colCount
                fprintf(fid, '%s\t', txtFieldName);
            else
                fprintf(fid, '%s\n', txtFieldName);
            end
        end
    end
    for r = 2:rowCount-1
        if all(cellfun(@(v) ~ischar(v) && isnan(v), {xlsData{r, :}})) %#ok<CCAT1>
            break
        end
        
        for c = 1:colCount
            xlsFieldName = xlsData{1, c};
            if isnan(xlsFieldName)
                % Do nothing, it's a blank column.
            else
                xlsValue = xlsData{r, c};
                
                if isnan(xlsValue)
                    txtValue = '';
                elseif strcmp(xlsFieldName, 'Well')
                    % Remove the 'Wellxx-' prefix and zero pad.
                    txtValue = regexprep(xlsValue, 'Well[0-9]*-', '');
                    txtValue = regexprep(txtValue, '([A-Z])([0-9])', '$10$2');
                elseif strcmp(xlsFieldName, 'construct')
                    % Convert '10dot1' to '10.1'
                    txtValue = strrep(xlsValue, 'dot', '.');
                else
                    txtValue = xlsValue;
                end
                
                if isnumeric(txtValue)
                    format = '%g';
                else
                    format = '%s';
                end
                
                if c < colCount
                    fprintf(fid, [format '\t'], txtValue);
                else
                    fprintf(fid, [format '\n'], txtValue);
                end
            end
        end
    end
    fclose(fid);
end
