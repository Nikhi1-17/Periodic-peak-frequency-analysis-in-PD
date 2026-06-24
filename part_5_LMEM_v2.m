clc; clearvars; close all;

addpath ('D:\NT lab\Publication_Project\results\feb_end')


%% -------------------------
% Fixed list of brain areas
% Rationale:
%   Using an explicit list avoids problems with empty area labels,
%   unexpected category values, and filename construction.
% -------------------------
areas = {'pre_SMA', 'SMA', 'SPL', 'M1_rec', 'M1_dom'};


%% -------------------------
% Output folder
% -------------------------
outdir = 'LMEM_disease_medication_TMS';
if ~exist(outdir, 'dir')
    mkdir(outdir);
end


%% -------------------------
% Load data
% -------------------------
addpath('D:/NT lab/Publication_Project/results/feb_end')
load('part_2_compilation.mat')   % loads "results"

% --- CLEAN AREA COLUMN ROBUSTLY ---
raw_area = results.Area;
clean_area = strings(size(raw_area));

for i = 1:numel(raw_area)
    val = raw_area{i};

    if ischar(val) || isstring(val)
        clean_area(i) = string(val);
    else
        try
            clean_area(i) = string(val);
        catch
            clean_area(i) = "";
        end
    end
end

results.Area = strtrim(clean_area);

% --- CLEAN GROUP COLUMN ---
results.Plot_x = strtrim(string(results.Plot_x));

%% 1. Change 'M1_rec' to 'M1_non_dom' in Area column

results.Area(results.Area == "M1_rec") = "M1_non_dom";


%% 2. Delete rows having NaN in Peak_freq_fft_1 or Peak_freq_fft_2

rows_to_keep = ~isnan(results.Peak_freq_fft_1) & ...
               ~isnan(results.Peak_freq_fft_2);

results_clean = results(rows_to_keep, :);


%% 3. Create separate tables based on unique entries in Area column
% Keep only selected columns

cols_needed = { ...
    'Patient_ID', ...
    'Disease_state', ...
    'Drug_state', ...
    'Peak_freq_fft_1', ...
    'Peak_freq_fft_2', ...
    'Aper_exp_1', ...
    'Aper_exp_2'};

unique_areas = unique(results_clean.Area);

% Store tables in a struct
area_tables = struct();

for i = 1:length(unique_areas)

    current_area = unique_areas(i);


    % Rows corresponding to this area
    idx = results_clean.Area == current_area;

    % Extract only required columns
    temp_table = results_clean(idx, cols_needed);

    % Make valid struct field name
    field_name = matlab.lang.makeValidName(current_area);

    % Store table
    area_tables.(field_name) = temp_table;

end

% START %
field_names = fieldnames(area_tables);
for i = 1:length(field_names)

    if i ==3 
        continue
    end

    disp (field_names (i));

    % Get current table
    T = area_tables.(field_names{i});

    T_dis = convert_cell_columns (T);

    % varfun(@class, T_dis, 'OutputFormat','table')


    % Convert to long format
    T_lme = convert_to_long_format(T);

    T_lme = convert_cell_columns (T_lme);

    lme_res = run_lme_models(T_lme);

    plot_lme_results (T_lme, lme_res);

    clc;

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function T_long = convert_to_long_format(T)
% ============================================================
% Converts wide-format table into long-format table for LME
%
% INPUT:
%   T : original table
%
% OUTPUT:
%   T_long : long-format table
%
% Assumptions:
%   Peak_freq_fft_1 = POST-TMS
%   Peak_freq_fft_2 = PRE-TMS
%
%   Aper_exp_1 = POST-TMS
%   Aper_exp_2 = PRE-TMS
% ============================================================
%% ------------------------------------------------------------
% Convert Drug_state for Healthy subjects to {}
%% ------------------------------------------------------------
idx_healthy = strcmp(T.Disease_state, 'Healthy');
T.Drug_state(idx_healthy) = {{}};
%% ------------------------------------------------------------
% Preallocate
%% ------------------------------------------------------------
n = height(T);
Patient_ID = cell(2*n,1);
Disease    = cell(2*n,1);
Drug       = cell(2*n,1);
TMS        = cell(2*n,1);
PeakFreq   = nan(2*n,1);
AperExp    = nan(2*n,1);
%% ------------------------------------------------------------
% Convert wide -> long
%% ------------------------------------------------------------
for i = 1:n
    % =========================
    % PRE-TMS row
    % =========================
    row_pre = 2*i - 1;
    Patient_ID{row_pre} = T.Patient_ID(i);
    Disease{row_pre}    = T.Disease_state{i};
    Drug{row_pre}       = T.Drug_state{i};
    TMS{row_pre}        = 'Pre';
    PeakFreq(row_pre)   = T.Peak_freq_fft_2(i);
    AperExp(row_pre)    = T.Aper_exp_2(i);
    % =========================
    % POST-TMS row
    % =========================
    row_post = 2*i;
    Patient_ID{row_post} = T.Patient_ID(i);
    Disease{row_post}    = T.Disease_state{i};
    Drug{row_post}       = T.Drug_state{i};
    TMS{row_post}        = 'Post';
    PeakFreq(row_post)   = T.Peak_freq_fft_1(i);
    AperExp(row_post)    = T.Aper_exp_1(i);
end
%% ------------------------------------------------------------
% Create final long-format table
%% ------------------------------------------------------------
T_long = table( ...
    Patient_ID, ...
    Disease, ...
    Drug, ...
    TMS, ...
    PeakFreq, ...
    AperExp);
end



function T = convert_cell_columns(T)

    % Get all variable names
    vars = T.Properties.VariableNames;

    for i = 1:length(vars)

        col = T.(vars{i});

        % Process only cell columns
        if iscell(col)

            new_col = strings(size(col));

            for j = 1:length(col)

                if isempty(col{j})
                    new_col(j) = "";
                else
                    new_col(j) = string(col{j});
                end

            end

            % Replace original column
            T.(vars{i}) = new_col;

        end
    end
end



function results = run_lme_models(T)

% ============================================================
% Fits 4 LME models:
%   Model 1: Healthy vs PD_OFF
%   Model 2: PD subjects with BOTH OFF and ON
%
% Outcomes:
%   1) PeakFreq
%   2) AperExp
%
% Assumes T has columns:
%   Patient_ID, Disease, Drug, TMS, PeakFreq, AperExp
% ============================================================

%% ---- Convert predictors to categorical with fixed order ----
T.Patient_ID = categorical(string(T.Patient_ID));
T.Disease    = categorical(string(T.Disease), {'Healthy','PD'});
T.Drug       = categorical(string(T.Drug), {'OFF','ON'});
T.TMS        = categorical(string(T.TMS), {'Pre','Post'});

results = struct();

%% ============================================================
% MODEL 1: Healthy vs PD_OFF
% Fixed effects: Disease, TMS, Disease*TMS
% Random effect: subject intercept
%% ============================================================

idx_m1 = (T.Disease == 'Healthy') | ((T.Disease == 'PD') & (T.Drug == 'OFF'));
T1 = T(idx_m1, :);

T1.Disease = categorical(string(T1.Disease), {'Healthy','PD'});
T1.TMS     = categorical(string(T1.TMS), {'Pre','Post'});

mdl_m1_peak = fitlme(T1, 'PeakFreq ~ Disease*TMS + (1|Patient_ID)');
mdl_m1_aper = fitlme(T1, 'AperExp  ~ Disease*TMS + (1|Patient_ID)');

anova_m1_peak = anova(mdl_m1_peak, 'DFMethod', 'satterthwaite');
anova_m1_aper  = anova(mdl_m1_aper, 'DFMethod', 'satterthwaite');

disp('================ MODEL 1: PeakFreq ================');
disp(anova_m1_peak);

disp('================ MODEL 1: AperExp ================');
disp(anova_m1_aper);

results.Model1.PeakFreq.Model = mdl_m1_peak;
results.Model1.PeakFreq.ANOVA = anova_m1_peak;
results.Model1.AperExp.Model  = mdl_m1_aper;
results.Model1.AperExp.ANOVA  = anova_m1_aper;

%% ============================================================
% MODEL 2: ALL PD subjects
%
% Includes:
%   - subjects with only OFF
%   - subjects with only ON
%   - subjects with both OFF and ON
%
% Fixed effects:
%   Drug, TMS, Drug*TMS
%
% Random effect:
%   (1|Patient_ID)
%% ============================================================

idx_m2 = (T.Disease == 'PD');

T2 = T(idx_m2, :);


%% ---- Ensure categorical variables ----

T2.Patient_ID = categorical(string(T2.Patient_ID));

T2.Drug = categorical(string(T2.Drug), ...
                      {'OFF','ON'});

T2.TMS  = categorical(string(T2.TMS), ...
                      {'Pre','Post'});


%% ============================================================
% Peak Frequency model
%% ============================================================

mdl_m2_peak = fitlme(T2, ...
    'PeakFreq ~ Drug*TMS + (1|Patient_ID)');

anova_m2_peak = anova(mdl_m2_peak, ...
    'DFMethod', 'satterthwaite');

disp('================ MODEL 2: PeakFreq ================');
disp(anova_m2_peak);


%% ============================================================
% Aperiodic exponent model
%% ============================================================

mdl_m2_aper = fitlme(T2, ...
    'AperExp ~ Drug*TMS + (1|Patient_ID)');

anova_m2_aper = anova(mdl_m2_aper, ...
    'DFMethod', 'satterthwaite');

disp('================ MODEL 2: AperExp ================');
disp(anova_m2_aper);


%% ============================================================
% Store results
%% ============================================================

results.Model2.PeakFreq.Model = mdl_m2_peak;
results.Model2.PeakFreq.ANOVA = anova_m2_peak;

results.Model2.AperExp.Model  = mdl_m2_aper;
results.Model2.AperExp.ANOVA  = anova_m2_aper;
end



function plot_lme_results(T, results)

% ============================================================
% Generates 2x2 subplot figure:
%
% Row 1 : PeakFreq
% Row 2 : AperExp
%
% Col 1 : MODEL 1 (Healthy vs PD_OFF)
% Col 2 : MODEL 2 (PD_OFF vs PD_ON)
%
% Requires:
%   T       -> long-format table
%   results -> output from run_lme_models()
%
% ============================================================

figure('Color','w','Position',[100 100 1400 900]);

vars = {'PeakFreq','AperExp'};

healthy_col = [0.20 0.65 0.20];   % green
pdoff_col   = [0.85 0.20 0.20];   % red
pdon_col    = [0.93 0.55 0.10];   % orange

for v = 1:2

    yvar = vars{v};

    %% =======================================================
    % MODEL 1
    % Healthy vs PD_OFF
    %% =======================================================

    subplot(2,2,(v-1)*2 + 1); hold on;

    idx1 = (T.Disease == "Healthy") | ...
           ((T.Disease == "PD") & (T.Drug == "OFF"));

    T1 = T(idx1,:);

    groups = {
        T1(T1.Disease=="Healthy",:)
        T1((T1.Disease=="PD") & (T1.Drug=="OFF"),:)
        };

    xCenters = [1 3];

    for g = 1:2

        if g == 1
            this_col = healthy_col;
        else
            this_col = pdoff_col;
        end

        Tg = groups{g};

        pre  = Tg(Tg.TMS=="Pre",:);
        post = Tg(Tg.TMS=="Post",:);

        x1 = xCenters(g)-0.25;
        x2 = xCenters(g)+0.25;

        % ---------------------------
        % Subject paired lines
        % ---------------------------

        commonIDs = intersect(pre.Patient_ID, post.Patient_ID);

        for i = 1:length(commonIDs)

            id = commonIDs(i);

            y1 = pre.(yvar)(pre.Patient_ID==id);
            y2 = post.(yvar)(post.Patient_ID==id);

            plot([x1 x2],[y1 y2], ...
                'Color',[0.7 0.7 0.7], ...
                'LineWidth',0.7);

        end

    % ---------------------------
    % Scatter
    % ---------------------------
    
    scatter(repmat(x1,height(pre),1), ...
        pre.(yvar), ...
        35,this_col,'filled');
    
    scatter(repmat(x2,height(post),1), ...
        post.(yvar), ...
        35,this_col,'filled');
    
    
    % ---------------------------
    % Boxplots
    % ---------------------------
    
    boxplot(pre.(yvar), ...
        'positions',x1, ...
        'Widths',0.18, ...
        'Colors',this_col, ...
        'Symbol','');
    
    boxplot(post.(yvar), ...
        'positions',x2, ...
        'Widths',0.18, ...
        'Colors',this_col, ...
        'Symbol','');

    end

    set(gca,'XTick',[0.75 1.25 2.75 3.25]);
    set(gca,'XTickLabel',{'B','A','B','A'});
    xlim([0.3 3.7]);

    ylabel(yvar);

    title(['MODEL 1 : ' yvar]);

    % ---------------------------
    % Group labels
    % ---------------------------

    yl = ylim;

    text(1, yl(2)*0.97, 'Healthy', ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold');

    text(3, yl(2)*0.97, 'PD OFF', ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold');

    % ---------------------------
    % p-values
    % ---------------------------

    if strcmp(yvar,'PeakFreq')
        A = results.Model1.PeakFreq.ANOVA;
    else
        A = results.Model1.AperExp.ANOVA;
    end

    txt = sprintf(['Disease p = %.3f\n' ...
                   'TMS p = %.3f\n' ...
                   'Interaction p = %.3f'], ...
                   A.pValue(2), ...
                   A.pValue(3), ...
                   A.pValue(4));

    text(0.4, yl(2)*0.85, txt, ...
        'FontSize',9, ...
        'BackgroundColor','w');



    %% =======================================================
    % MODEL 2
    % PD_OFF vs PD_ON
    %% =======================================================

    subplot(2,2,(v-1)*2 + 2); hold on;

    idx2 = (T.Disease == "PD");

    T2 = T(idx2,:);

    groups = {
        T2(T2.Drug=="OFF",:)
        T2(T2.Drug=="ON",:)
        };

    xCenters = [1 3];

    for g = 1:2

    if g == 1
        this_col = pdoff_col;
    else
        this_col = pdon_col;
    end

        Tg = groups{g};

        pre  = Tg(Tg.TMS=="Pre",:);
        post = Tg(Tg.TMS=="Post",:);

        x1 = xCenters(g)-0.25;
        x2 = xCenters(g)+0.25;

        % ---------------------------
        % Subject paired lines
        % ---------------------------

        commonIDs = intersect(pre.Patient_ID, post.Patient_ID);

        for i = 1:length(commonIDs)

            id = commonIDs(i);

            y1 = pre.(yvar)(pre.Patient_ID==id);
            y2 = post.(yvar)(post.Patient_ID==id);

            plot([x1 x2],[y1 y2], ...
                'Color',[0.7 0.7 0.7], ...
                'LineWidth',0.7);

        end

    % ---------------------------
    % Scatter
    % ---------------------------
    
    scatter(repmat(x1,height(pre),1), ...
        pre.(yvar), ...
        35,this_col,'filled');
    
    scatter(repmat(x2,height(post),1), ...
        post.(yvar), ...
        35,this_col,'filled');
    
    
    % ---------------------------
    % Boxplots
    % ---------------------------
    
    boxplot(pre.(yvar), ...
        'positions',x1, ...
        'Widths',0.18, ...
        'Colors',this_col, ...
        'Symbol','');
    
    boxplot(post.(yvar), ...
        'positions',x2, ...
        'Widths',0.18, ...
        'Colors',this_col, ...
        'Symbol','');

    end

    set(gca,'XTick',[0.75 1.25 2.75 3.25]);
    set(gca,'XTickLabel',{'B','A','B','A'});
    xlim([0.3 3.7]);

    ylabel(yvar);

    title(['MODEL 2 : ' yvar]);

    yl = ylim;

    text(1, yl(2)*0.97, 'PD OFF', ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold');

    text(3, yl(2)*0.97, 'PD ON', ...
        'HorizontalAlignment','center', ...
        'FontWeight','bold');

    % ---------------------------
    % p-values
    % ---------------------------

    if strcmp(yvar,'PeakFreq')
        A = results.Model2.PeakFreq.ANOVA;
    else
        A = results.Model2.AperExp.ANOVA;
    end

    txt = sprintf(['Drug p = %.3f\n' ...
                   'TMS p = %.3f\n' ...
                   'Interaction p = %.3f'], ...
                   A.pValue(2), ...
                   A.pValue(3), ...
                   A.pValue(4));

    text(0.4, yl(2)*0.85, txt, ...
        'FontSize',9, ...
        'BackgroundColor','w');

end

sgtitle('LME Results');

end