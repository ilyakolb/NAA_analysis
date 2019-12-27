function construct_viewer()



hctrlfig=figure('position',[900,200,350,550],'Resize','off','DeleteFcn',@ctrlfigDelCallback);
uicontrol(hctrlfig,'Tag','ListConstruct','Style','listbox','Units','pixel','position',[25,15,200,525],'Max',2,'Callback',@ListConstructCallback,'KeyPressFcn', @keyPressFcn);
uicontrol(hctrlfig,'Tag','BnLoad','Style','pushbutton','Units','pixel','position',[260,130,70,25],'String','LoadData','Callback',@BnLoadCallback);
uicontrol(hctrlfig,'Tag','BnBarPlot','Style','pushbutton','Units','pixel','position',[260,160,70,25],'String','BarPlot','Callback',@BnBarPlotCallback);
uicontrol(hctrlfig,'Tag','BnTracePlot','Style','pushbutton','Units','pixel','position',[260,190,70,25],'String','TracePlot','Callback',@BnTracePlotCallback);
mutant_data=[];
mutant_data_norm=[];
control_data=[];
control_data_norm=[];
hobjs=guihandles(hctrlfig);
IsNormalize=1;
    function BnLoadCallback(varargin)
        [mutant_data,mutant_data_norm,control_data,control_data_norm]=NAA_pile_mutants();
%         mutant_data=NAA_pile_mutants();
        update_view();
    end



    function BnTracePlotCallback(varargin)
        str=get(hobjs.ListConstruct,'string');
        sel_ind=get(hobjs.ListConstruct,'value');
        selected=str(sel_ind);
        
%         selected_all=false(1,length(mutant_data));
%         name_all={mutant_data.construct};
%         
                selected_all=sel_ind;
%         for i=1:length(selected)
%             selected_all= selected_all | strcmp(name_all,selected{i});
%         end
        
        NAA_compare_traceplot(mutant_data(selected_all));
    end


    function BnBarPlotCallback(varargin)
        str=get(hobjs.ListConstruct,'string');
        sel_ind=get(hobjs.ListConstruct,'value');
        selected=str(sel_ind);
        
% %         selected_all=false(1,length(mutant_data));
% %         name_all={mutant_data.construct};
%         for i=1:length(selected)
%             selected_all= selected_all | strcmp(name_all,selected{i});
%         end
        
        selected_all=sel_ind;
%       field='df_fpeak_med';
        field='df_fpeak_med_comp';
        IsNormalize=0;
%         field='decay_half_med';
        if IsNormalize==0
            NAA_compare_barplot(mutant_data(selected_all),control_data(selected_all),field,3);
        else 
            NAA_compare_barplot(mutant_data_norm(selected_all),control_data_norm(selected_all),field,9);
        end
    end

    function update_view
        %name={mutant_data.construct};
        name={mutant_data.fullname};
        set(hobjs.ListConstruct,'string',name);
    end
        
    function ctrlfigDelCallback(varargin)
    end

    function ListConstructCallback(varargin)
    end

    function keyPressFcn(varargin)
    end

end