function NAA_display_Plate(type)
% Create the PDF
if strcmp(type,'GCaMP96b-ERtag')
    type='GCaMP96b';
end
if strcmp(type, 'GCaMP96') ||strcmpi(type, 'GCaMP96b') || strcmpi(type, 'RCaMP96')|| strcmpi(type, 'RCaMP96b')||strcmpi(type, 'FRET96') ||strcmpi(type, 'OGB1')|| strcmpi(type, 'RCaMP96c')||strcmpi(type, 'GCaMP96z')  %OGB added by Hod 20131125 %% FRET96 was added by Hod 01Apr2013, GCaMP96z on 20160919
    row = {'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'};
    col = {'01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'};
    nAP = [1, 3, 10, 160];
    clim_high = [0.3, 0.7, 1.5, 7];
else
    row = {'A', 'B', 'C', 'D'};
    col = {'1', '2', '3', '4', '5', '6'};
    nAP = [1, 2, 3, 5, 10, 20, 40, 80, 160];
    clim_high = [0.3, 0.5, 0.7, 0.9, 1.5, 3, 4, 6, 7];
end

ntotalwell = length(row) * length(col);
well_names=cell(1, ntotalwell);
for i = 1:length(row)
    for j = 1:length(col)
        well_num = length(col) * (i - 1) + j;
        well_names{well_num} = [row{i}, col{j}];
    end
end

master_result=cell(ntotalwell, 1);
for i=1:ntotalwell
    file=dir(['*',well_names{i},'_*.mat']);
    if ~isempty(file)
        a=textscan(file.name,'%s','delimiter','_');
        plate_name=a{1}{1};
        if strcmpi(type, 'FRET') || strcmpi(type, 'FRET96')
            S=load([file(1).name],'CFP_base','mCherry','cell_list','summaryRatio','dr_rmap');
        else
            S=load([file(1).name],'GCaMPbase','mCherry','cell_list','summary','df_fmap');
        end
        master_result{i}=S;
        if strcmpi(type, 'GCaMP96') ||strcmpi(type, 'GCaMP96b') || strcmpi(type, 'RCaMP96')||strcmpi(type, 'RCaMP96b')||strcmpi(type, 'FRET96') ||strcmpi(type, 'OGB1')|| strcmpi(type, 'RCaMP96c')||strcmpi(type, 'GCaMP96z') %OGB added by Hod 20131125 %% FRET96 was added by Hod 01Apr2013
            center=[S.cell_list.center];
            distmat=squareform(pdist(center'));
            n_nearby=sum(distmat<50)-1;
            master_result{i}.n_nearby=n_nearby;
        end
    end
end

pdf_name = [plate_name,'.pdf'];

if exist(pdf_name, 'file')
    disp('Results PDF file already exists.');
else
    % Figure out the dimensions of the figure.
    if ntotalwell == 24
        fig_cols = 6;
        fig_rows = 4;
    elseif ntotalwell == 96
        fig_cols = 12;
        fig_rows = 8;
    else
        fig_cols = 6;
        fig_rows = ceil(ntotalwell / 6);
    end
    axes_width = 1.0 / fig_cols;
    axes_height = 1.0 / fig_rows;
    
    % Create a figure scaled to the number of rows and columns with a maximum size of 2400.
    % For some reason anything bigger than that causes any axes positioned beyond 2400 to be cropped out of the PDF.
    if fig_rows > fig_cols
        fig_height = 2400;
        fig_width = fig_height * fig_cols / fig_rows;
    else
        fig_width = 2400;
        fig_height = fig_width * fig_rows / fig_cols;
    end
    fig_h = figure('Position', [1, 1, fig_width + 1, fig_height + 1], 'Visible', 'off');
    
    warning('off', 'MATLAB:LargeImage');
    
    for i = 1:ntotalwell
        mr = master_result{i};
        axes('OuterPosition', [axes_width * mod(i - 1, fig_cols), 1.0 - axes_height * ceil(i / fig_cols), axes_width, axes_height]);  %#ok<LAXES>
        if isempty(mr)
            if strcmp(type, 'FRET') || strcmpi(type, 'FRET96')
                segment_name = 'Segmentation.mat';
                base_name = 'CFP_base';
            else
                segment_name = 'segmentation_cherry.mat';
                base_name = 'GCaMPbase';
            end
            well_dir = dir(fullfile('..', ['*' well_names{i}]));
            if isempty(well_dir)
                file = [];
            else
                file = dir(fullfile('..', well_dir(1).name, segment_name));
            end
            if isempty(file)
                if strcmp(type, 'FRET') || strcmpi(type, 'FRET96')
                    overlay = zeros(240, 500);
                else
                    overlay = zeros(512, 512);
                end
                colormap('hot');    % so 0 = black
            else
                S = load(fullfile('..', well_dir(1).name, segment_name), base_name, 'mCherry');
                %modified by Hod 20140811
                %                     if strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b')
                %                         overlay = NAA_create_overlay(S.mCherry, S.(base_name));
                %                     else
                overlay = NAA_create_overlay(S.(base_name), S.mCherry);
                %                     end
                %                   end of change HD
            end
        elseif strcmp(type, 'FRET') || strcmpi(type, 'FRET96')
            overlay = NAA_create_overlay(mr.CFP_base, mr.mCherry);
        elseif strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b')|| strcmpi(type, 'RCaMP96c')
            overlay = NAA_create_overlay(mr.mCherry, mr.GCaMPbase);
        else
            overlay = NAA_create_overlay(mr.GCaMPbase, mr.mCherry);
        end
        image(overlay);  axis image;
        set(gca, 'XTick', [], 'YTick', []);
        if isempty(mr)
            title_string = well_names{i};
            radius = size(overlay, 1) / 2;
            offset = (radius - 16) * sin(pi/4);
            rectangle('Position', [16, 16, radius * 2 - 32, radius * 2 - 32], ...
                'Curvature', [1, 1], ...
                'EdgeColor', [0.5 0 0], ...
                'LineWidth', 8);
            line([radius - offset, radius + offset], [radius + offset, radius - offset], ...
                'Color', [0.5 0 0], ...
                'LineWidth', 8);
        elseif strcmpi(type, 'GCaMP96') ||strcmpi(type, 'GCaMP96b') || strcmpi(type, 'RCaMP96') || strcmpi(type, 'RCaMP96b') || strcmpi(type, 'OGB1')|| strcmpi(type, 'RCaMP96c')||strcmpi(type, 'GCaMP96z')
            title_string = [well_names{i}, '#=', num2str(length(mr.n_nearby)), ' Cmax=', num2str(max(mr.n_nearby)), ' dff10=', num2str(mr.summary.df_fpeak(3), '%0.2f')];
        elseif strcmpi(type, 'GCaMP')
            title_string = [well_names{i},' dff10=', num2str(mr.summary.df_fpeak(5), '%0.2f')];
        elseif strcmpi(type, 'FRET96')
            title_string = [well_names{i},' dff10=', num2str(mr.summaryRatio.df_fpeak(3), '%0.2f')];
        else %FRET
            title_string = [well_names{i},' dff10=', num2str(mr.summaryRatio.df_fpeak(5), '%0.2f')];
        end
        title(title_string, 'FontUnits', 'normalized', 'FontSize', .08);
    end
    
%     export_fig(pdf_name, '-nocrop', fig_h);%update to Matlab r2016a, HD 20160804
figure(fig_h)
print(pdf_name,'-dpdf','-fillpage')
    clf(fig_h);
    
    for k=1:length(nAP)
        for i = 1:ntotalwell
            mr = master_result{i};
            axes('OuterPosition', [axes_width * mod(i - 1, fig_cols), 1.0 - axes_height * ceil(i / fig_cols), axes_width, axes_height]);  %#ok<LAXES>
            if isempty(mr)
                if strcmp(type, 'FRET') || strcmpi(type, 'FRET96')
                    image_data = zeros(240, 500);
                else
                    image_data = zeros(512, 512);
                end
            elseif strcmp(type, 'FRET') || strcmpi(type, 'FRET96')
                image_data = mr.dr_rmap(:, :, k);
            else
                image_data = mr.df_fmap(:, :, k);
            end
            imagesc(image_data); axis image; set(gca, 'clim', [0, clim_high(k)]);
            set(gca, 'XTick', [], 'YTick', []);
            title([well_names{i}, '  ', num2str(nAP(k)), 'FP'], 'FontUnits', 'normalized', 'FontSize', .08);
            if isempty(mr)
                radius = size(image_data, 1) / 2;
                offset = (radius - 16) * sin(pi/4);
                rectangle('Position', [16, 16, radius * 2 - 32, radius * 2 - 32], ...
                    'Curvature', [1, 1], ...
                    'EdgeColor', [0.5 0 0], ...
                    'LineWidth', 8);
                line([radius - offset, radius + offset], [radius + offset, radius - offset], ...
                    'Color', [0.5 0 0], ...
                    'LineWidth', 8);
            end
        end
        
%         export_fig(pdf_name, '-nocrop', '-append', fig_h); %update to Matlab r2016a, HD 20160804
figure(fig_h)
print([pdf_name k '_AP'],'-dpdf','-fillpage')
        clf(fig_h);
    end
    
    warning('on', 'MATLAB:LargeImage');
    
    % Make the figure visible before deleting it to work around bug that causes the code to sometimes fail to exit when run on the cluster.
    set(fig_h, 'Visible', 'on');
    drawnow;
    delete(fig_h);
end
end
