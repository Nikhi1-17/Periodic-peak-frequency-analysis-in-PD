clc, clearvars, close all;

% Below is continuation of part_2_compilation 
% PART 3 - Here we will do the plotting of all the features

% Here is the scheme

% Each plot contains 8 subplots. 
% Each subplot contains two pairs of bar plots. 
% Y axis - feature
% X axis - Healthy vs PD_OFF      PD_OFF vs PD_ON
% Fig saved in folder feb_end in a folder called norm_corr_comp_fig_1 and
% norm_corr_comp_fig_2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load MAIN results
addpath('D:/NT lab/Publication_Project/results/feb_end')

load('part_2_compilation.mat');   % loads variable: results

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plotting for fig 1 
% These plots correspond to 
%  %%% %%% POST-STIM DATA %%% %%%

outdir = 'norm_corr_comp_fig_1';
if ~exist(outdir,'dir')
    mkdir(outdir);
end

%% -------------------------
% Areas & datatypes
%% -------------------------

% Find cells that are empty OR contain []
empty_idx = cellfun(@(x) isempty(x), results.Area);
% Replace them with missing
results.Area(empty_idx) = {''};  
% Now convert safely
area_str = string(results.Area);
% Convert to categorical
results.Area = categorical(area_str);
% Get categories
areas = categories(results.Area);

%% -------------------------
% Variables, subtitles, y-limits
%% -------------------------
vars = {'Peak_freq_fft_1','Power_a_pf_1','Aper_exp_1','Aper_offset_1', ...
        'auc_psd_1','auc_aper_1','auc_per_1' ,'norm_papf_1'};

subtitles = {'Peak freq','Power at peak freq', 'Exponent',...
             'Offset', 'Total power','Aperiodic power','Periodic power', 'Norm power at peak freq'};

ylims = {[0 50], [0 2], [0 6], [0 6], [0 5.5], [0 5.5], [0 5.5], [0 0.004]};

%% -------------------------
% Colours
%% -------------------------
colH = [0.2 0.7 0.2];   % Healthy
colO = [0.85 0.2 0.2];  % PD_OFF
colN = [1.0 0.55 0.0];  % PD_ON
colLines = [0.7 0.7 0.7];

%% ================================
% Main loop
%% ================================

    for a = 1:numel(areas)

        area = areas{a};
        T = results(results.Area == area, :);
        if height(T)==0, continue; end

        % Display name
        area_disp = area;
        if strcmp(area,'M1_rec')
            area_disp = 'M1_non_dom';
        end

        %% -------------------------
        % Figure
        %% -------------------------
        figure('Color','w','Position',[100 100 1600 700]);
        sgtitle(sprintf('%s',area_disp), ...
            'FontWeight','bold','Interpreter','none');

        for k = 1:8
            subplot(2,4,k); hold on;
            yvar = [vars{k}];

            if ~ismember(yvar,T.Properties.VariableNames)
                title(subtitles{k}); box on; continue;
            end

            %% Groups
            H = T(T.Plot_x=='Healthy',:);
            O = T(T.Plot_x=='PD_OFF',:);
            N = T(T.Plot_x=='PD_ON',:);

            yH = double(H.(yvar));
            yO = double(O.(yvar));
            yN = double(N.(yvar));

            %% Paired
            [~,ia,ib] = intersect(string(O.Patient_ID),string(N.Patient_ID),'stable');
            yOp = yO(ia);
            yNp = yN(ib);

            %% X positions
            xH=1; xO1=2; xO2=4; xN=5;

            %% Boxplots (coloured)
            boxplot(yH,'Positions',xH,'Widths',0.5,'Colors',colH);
            boxplot(yO,'Positions',xO1,'Widths',0.5,'Colors',colO);
            boxplot(yOp,'Positions',xO2,'Widths',0.5,'Colors',colO);
            boxplot(yN,'Positions',xN,'Widths',0.5,'Colors',colN);

            %% Scatter (same colour, 50% smaller)
            scatter(xH + 0.05*randn(size(yH)), yH, 12, colH,'filled');
            scatter(xO1+ 0.05*randn(size(yO)), yO, 12, colO,'filled');
            scatter(xO2+ 0.05*randn(size(yOp)),yOp,12, colO,'filled');
            scatter(xN + 0.05*randn(size(yN)), yN, 12, colN,'filled');

            %% Paired lines
            for i=1:numel(yOp)
                plot([xO2 xN],[yOp(i) yNp(i)],'-','Color',colLines);
            end

            %% Sample sizes (moved down to avoid overlap)
            yl = ylims{k};
            ytxt = yl(1) - 0.15*range(yl);

            text(xH, ytxt, sprintf('n=%d',sum(~isnan(yH))), 'HorizontalAlignment','center');
            text(xO1,ytxt, sprintf('n=%d',sum(~isnan(yO))), 'HorizontalAlignment','center');
            text(xO2,ytxt, sprintf('n=%d',sum(~isnan(yOp))),'HorizontalAlignment','center');
            text(xN, ytxt, sprintf('n=%d',sum(~isnan(yN))), 'HorizontalAlignment','center');

            %% =========================
            % Statistics
            %% =========================
            
            % ---------- Healthy vs PD_OFF (unpaired)
            p_HO = NaN;
            
            x = yH(~isnan(yH));   % Healthy
            y = yO(~isnan(yO));   % PD_OFF
            
            if numel(x) >= 3 && numel(y) >= 3
            
                % Normality (Shapiro–Wilk)
                [~, sw_x_h] = swtest(x, 0.05);
                [~, sw_y_h] = swtest(y, 0.05);
            
                if sw_x_h == 0 && sw_y_h == 0
                    % Equal variance check (Levene)
                    group_labels = [ones(size(x)); 2*ones(size(y))];
                    combined = [x; y];
            
                    p_levene = vartestn(combined, group_labels, ...
                        'TestType','LeveneAbsolute','Display','off');
            
                    if p_levene > 0.05
                        % Student's t-test
                        [~, p_HO, ~, stats] = ttest2(x, y, 'Vartype','equal');
                    else
                        % Welch's t-test
                        [~, p_HO, ~, stats] = ttest2(x, y, 'Vartype','unequal');
                    end
                else
                    % Mann–Whitney U
                    [p_HO, ~, stats] = ranksum(x, y);
                end
            end
            
            % ---------- PD_OFF (paired) vs PD_ON
            p_ON = NaN;
            
            x2 = yOp(~isnan(yOp));   % PD_OFF paired
            y2 = yNp(~isnan(yNp));   % PD_ON paired
            
            if numel(x2) >= 3 && numel(y2) >= 3
            
                % Normality (Shapiro–Wilk)
                [h_on,  ~] = swtest(y2, 0.05);
                [h_off, ~] = swtest(x2, 0.05);
            
                if (~h_on) && (~h_off)
                    % Paired t-test
                    [~, p_ON, ~, stats] = ttest(y2, x2);
                else
                    % Wilcoxon signed-rank
                    [p_ON, ~, stats] = signrank(y2, x2);
                end
            end
            
            %% =========================
            % Plot only significant p-values
            %% =========================
            ystat = yl(2) + 0.05*range(yl);
            
            if ~isnan(p_HO) && p_HO < 0.05
                plot([xH xO1], [ystat ystat], 'k', 'LineWidth',1);
                text(mean([xH xO1]), ystat, sprintf('p=%.3g', p_HO), ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom');
            end
            
            if ~isnan(p_ON) && p_ON < 0.05
                plot([xO2 xN], [ystat ystat], 'k', 'LineWidth',1);
                text(mean([xO2 xN]), ystat, sprintf('p=%.3g', p_ON), ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom');
            end


            %% Axes
            ylim(ylims{k});
            xlim([0.5 5.5]);
            set(gca,'XTick',[xH xO1 xO2 xN], ...
                'XTickLabel',{'Healthy','PD_OFF','PD_OFF','PD_ON'}, ...
                'TickLabelInterpreter','none');
            title(subtitles{k});
            box on;
        end

        %% Save
        fname = sprintf('%s.png',area_disp);
        saveas(gcf, fullfile(outdir,fname));
    end

disp ('Completed plotting data for post stim (subscriptted variables as 1)')
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% These plots correspond to 
%  %%% %%% PRE-STIM DATA %%% %%%

outdir = 'norm_corr_comp_fig_2';
if ~exist(outdir,'dir')
    mkdir(outdir);
end

% %% -------------------------
% % Areas & datatypes
% %% -------------------------
% 
% % Find cells that are empty OR contain []
% empty_idx = cellfun(@(x) isempty(x), results.Area);
% % Replace them with missing
% results.Area(empty_idx) = {''};  
% % Now convert safely
% area_str = string(results.Area);
% % Convert to categorical
% results.Area = categorical(area_str);
% % Get categories
% areas = categories(results.Area);

%% -------------------------
% Variables, subtitles, y-limits
%% -------------------------
vars = {'Peak_freq_fft_2','Power_a_pf_2','Aper_exp_2','Aper_offset_2', ...
        'auc_psd_2','auc_aper_2','auc_per_2' ,'norm_papf_2'};

subtitles = {'Peak freq','Power at peak freq', 'Exponent',...
             'Offset', 'Total power','Aperiodic power','Periodic power', 'Norm power at peak freq'};

ylims = {[0 50], [0 2], [0 6], [0 6], [0 5.5], [0 5.5], [0 5.5], [0 0.004]};

%% -------------------------
% Colours
%% -------------------------
colH = [0.2 0.7 0.2];   % Healthy
colO = [0.85 0.2 0.2];  % PD_OFF
colN = [1.0 0.55 0.0];  % PD_ON
colLines = [0.7 0.7 0.7];

%% ================================
% Main loop
%% ================================

    for a = 1:numel(areas)

        area = areas{a};
        T = results(results.Area == area, :);
        if height(T)==0, continue; end

        % Display name
        area_disp = area;
        if strcmp(area,'M1_rec')
            area_disp = 'M1_non_dom';
        end

        %% -------------------------
        % Figure
        %% -------------------------
        figure('Color','w','Position',[100 100 1600 700]);
        sgtitle(sprintf('%s',area_disp), ...
            'FontWeight','bold','Interpreter','none');

        for k = 1:8
            subplot(2,4,k); hold on;
            yvar = [vars{k}];

            if ~ismember(yvar,T.Properties.VariableNames)
                title(subtitles{k}); box on; continue;
            end

            %% Groups
            H = T(T.Plot_x=='Healthy',:);
            O = T(T.Plot_x=='PD_OFF',:);
            N = T(T.Plot_x=='PD_ON',:);

            yH = double(H.(yvar));
            yO = double(O.(yvar));
            yN = double(N.(yvar));

            %% Paired
            [~,ia,ib] = intersect(string(O.Patient_ID),string(N.Patient_ID),'stable');
            yOp = yO(ia);
            yNp = yN(ib);

            %% X positions
            xH=1; xO1=2; xO2=4; xN=5;

            %% Boxplots (coloured)
            boxplot(yH,'Positions',xH,'Widths',0.5,'Colors',colH);
            boxplot(yO,'Positions',xO1,'Widths',0.5,'Colors',colO);
            boxplot(yOp,'Positions',xO2,'Widths',0.5,'Colors',colO);
            boxplot(yN,'Positions',xN,'Widths',0.5,'Colors',colN);

            %% Scatter (same colour, 50% smaller)
            scatter(xH + 0.05*randn(size(yH)), yH, 12, colH,'filled');
            scatter(xO1+ 0.05*randn(size(yO)), yO, 12, colO,'filled');
            scatter(xO2+ 0.05*randn(size(yOp)),yOp,12, colO,'filled');
            scatter(xN + 0.05*randn(size(yN)), yN, 12, colN,'filled');

            %% Paired lines
            for i=1:numel(yOp)
                plot([xO2 xN],[yOp(i) yNp(i)],'-','Color',colLines);
            end

            %% Sample sizes (moved down to avoid overlap)
            yl = ylims{k};
            ytxt = yl(1) - 0.15*range(yl);

            text(xH, ytxt, sprintf('n=%d',sum(~isnan(yH))), 'HorizontalAlignment','center');
            text(xO1,ytxt, sprintf('n=%d',sum(~isnan(yO))), 'HorizontalAlignment','center');
            text(xO2,ytxt, sprintf('n=%d',sum(~isnan(yOp))),'HorizontalAlignment','center');
            text(xN, ytxt, sprintf('n=%d',sum(~isnan(yN))), 'HorizontalAlignment','center');

            %% =========================
            % Statistics
            %% =========================
            
            % ---------- Healthy vs PD_OFF (unpaired)
            p_HO = NaN;
            
            x = yH(~isnan(yH));   % Healthy
            y = yO(~isnan(yO));   % PD_OFF
            
            if numel(x) >= 3 && numel(y) >= 3
            
                % Normality (Shapiro–Wilk)
                [~, sw_x_h] = swtest(x, 0.05);
                [~, sw_y_h] = swtest(y, 0.05);
            
                if sw_x_h == 0 && sw_y_h == 0
                    % Equal variance check (Levene)
                    group_labels = [ones(size(x)); 2*ones(size(y))];
                    combined = [x; y];
            
                    p_levene = vartestn(combined, group_labels, ...
                        'TestType','LeveneAbsolute','Display','off');
            
                    if p_levene > 0.05
                        % Student's t-test
                        [~, p_HO, ~, stats] = ttest2(x, y, 'Vartype','equal');
                    else
                        % Welch's t-test
                        [~, p_HO, ~, stats] = ttest2(x, y, 'Vartype','unequal');
                    end
                else
                    % Mann–Whitney U
                    [p_HO, ~, stats] = ranksum(x, y);
                end
            end
            
            % ---------- PD_OFF (paired) vs PD_ON
            p_ON = NaN;
            
            x2 = yOp(~isnan(yOp));   % PD_OFF paired
            y2 = yNp(~isnan(yNp));   % PD_ON paired
            
            if numel(x2) >= 3 && numel(y2) >= 3
            
                % Normality (Shapiro–Wilk)
                [h_on,  ~] = swtest(y2, 0.05);
                [h_off, ~] = swtest(x2, 0.05);
            
                if (~h_on) && (~h_off)
                    % Paired t-test
                    [~, p_ON, ~, stats] = ttest(y2, x2);
                else
                    % Wilcoxon signed-rank
                    [p_ON, ~, stats] = signrank(y2, x2);
                end
            end
            
            %% =========================
            % Plot only significant p-values
            %% =========================
            ystat = yl(2) + 0.05*range(yl);
            
            if ~isnan(p_HO) && p_HO < 0.05
                plot([xH xO1], [ystat ystat], 'k', 'LineWidth',1);
                text(mean([xH xO1]), ystat, sprintf('p=%.3g', p_HO), ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom');
            end
            
            if ~isnan(p_ON) && p_ON < 0.05
                plot([xO2 xN], [ystat ystat], 'k', 'LineWidth',1);
                text(mean([xO2 xN]), ystat, sprintf('p=%.3g', p_ON), ...
                    'HorizontalAlignment','center','VerticalAlignment','bottom');
            end


            %% Axes
            ylim(ylims{k});
            xlim([0.5 5.5]);
            set(gca,'XTick',[xH xO1 xO2 xN], ...
                'XTickLabel',{'Healthy','PD_OFF','PD_OFF','PD_ON'}, ...
                'TickLabelInterpreter','none');
            title(subtitles{k});
            box on;
        end

        %% Save
        fname = sprintf('%s.png',area_disp);
        saveas(gcf, fullfile(outdir,fname));
    end

disp ('Completed plotting data for pre stim (subscriptted variables as 2)')
close all;

%% -------------------------
% Helper
%% -------------------------
function out = ternary(cond,a,b)
if cond, out=a; else, out=b; end
end

 