clc; clearvars; close all;

set(groot, 'defaultTextInterpreter', 'none');
set(groot, 'defaultLegendInterpreter', 'none');
set(groot, 'defaultAxesTickLabelInterpreter', 'none');

% Load MAIN results
addpath('D:/NT lab/Publication_Project/results/feb_end')
load('part_2_compilation.mat');   % loads variable: results

nRows = height(results);

total_1     = cell(nRows,1);
aperiodic_1 = cell(nRows,1);
periodic_1  = cell(nRows,1);

total_2     = cell(nRows,1);
aperiodic_2 = cell(nRows,1);
periodic_2  = cell(nRows,1);

for i = 1:nRows
    
    % ---------- FOOOF_output_1 ----------
    if ~isempty(results.FOOOF_output_1{i}) && isstruct(results.FOOOF_output_1{i})
        
        s1 = results.FOOOF_output_1{i};
        
        total_1{i}     = s1.fooofed_spectrum;
        aperiodic_1{i} = s1.ap_fit;
        
        diff_lin = 10.^s1.fooofed_spectrum - 10.^s1.ap_fit;
        diff_lin(diff_lin <= 0) = NaN;
        
        periodic_1{i}  = log10(diff_lin);
    end

    % ---------- FOOOF_output_2 ----------
    if ~isempty(results.FOOOF_output_2{i}) && isstruct(results.FOOOF_output_2{i})
        
        s2 = results.FOOOF_output_2{i};
        
        total_2{i}     = s2.fooofed_spectrum;
        aperiodic_2{i} = s2.ap_fit;
        
        diff_lin = 10.^s2.fooofed_spectrum - 10.^s2.ap_fit;
        diff_lin(diff_lin <= 0) = NaN;
        
        periodic_2{i}  = log10(diff_lin);
    end

end

% Add to table
results.total_1     = total_1;
results.aperiodic_1 = aperiodic_1;
results.periodic_1  = periodic_1;

results.total_2     = total_2;
results.aperiodic_2 = aperiodic_2;
results.periodic_2  = periodic_2;

%% -------- Plotting: Post-stim (total_1, aperiodic_1, periodic_1) --------

save_dir = 'D:\NT lab\Publication_Project\results\feb_end\power_spectrum_comparison';

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

% areas = unique(results.Area);
areas = [{'pre_SMA' }, {'SMA' }, {'SPL' }, {'M1_rec' }, {'M1_dom' }];

% Get frequency vector from first valid row
freqs = [];
for i = 1:height(results)
    if ~isempty(results.FOOOF_output_1{i}) && isstruct(results.FOOOF_output_1{i})
        freqs = results.FOOOF_output_1{i}.freqs;
        break;
    end
end

if isempty(freqs)
    error('No valid frequency vector found.');
end

% Colors (nice contrast)
col_healthy = [0 0.6 0];      % green
col_pd_off  = [0.8 0 0];      % red
col_pd_on   = [1 0.5 0];      % orange

for a = 1:length(areas)
    
    area_name = areas{a};
    
    % Filter rows for this area
    idx_area = strcmp(results.Area, area_name);
    T = results(idx_area,:);
    
    figure('Name', area_name, 'Color', 'w');
    sgtitle([area_name ' : Post-stim']);
    
    % ---------- LEFT COLUMN: Healthy vs PD_OFF ----------
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'total_1', 'Total', 1, col_healthy, col_pd_off);
    
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'aperiodic_1', 'Aperiodic', 3, col_healthy, col_pd_off);
    
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'periodic_1', 'Periodic', 5, col_healthy, col_pd_off);
    
    
    % ---------- RIGHT COLUMN: PD_ON vs PD_OFF ----------
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'total_1', 'Total', 2, col_pd_on, col_pd_off);
    
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'aperiodic_1', 'Aperiodic', 4, col_pd_on, col_pd_off);
    
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'periodic_1', 'Periodic', 6, col_pd_on, col_pd_off);
  
    % Clean filename (avoid issues with special characters)
    safe_area = strrep(area_name, ' ', '_');
    
    % Full file path
    save_path = fullfile(save_dir, [safe_area '_PostStim']);
    
    % Save as .png (high resolution)
    exportgraphics(gcf, [save_path '.png'], 'Resolution', 300);
    
    % Also save MATLAB figure (optional but useful)
    savefig(gcf, [save_path '.fig']);

end

%% -------- Plotting: Pre-stim (total_2, aperiodic_2, periodic_2) --------

save_dir = 'D:\NT lab\Publication_Project\results\feb_end\power_spectrum_comparison';

if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

areas = [{'pre_SMA' }, {'SMA' }, {'SPL' }, {'M1_rec' }, {'M1_dom' }];

% Get frequency vector from first valid row (FOOOF_output_2 now)
freqs = [];
for i = 1:height(results)
    if ~isempty(results.FOOOF_output_2{i}) && isstruct(results.FOOOF_output_2{i})
        freqs = results.FOOOF_output_2{i}.freqs;
        break;
    end
end

if isempty(freqs)
    error('No valid frequency vector found.');
end

% Colors
col_healthy = [0 0.6 0];      % green
col_pd_off  = [0.8 0 0];      % red
col_pd_on   = [1 0.5 0];      % orange

for a = 1:length(areas)
    
    area_name = areas{a};
    
    % Filter rows for this area
    idx_area = strcmp(results.Area, area_name);
    T = results(idx_area,:);
    
    figure('Name', area_name, 'Color', 'w');
    sgtitle([area_name ' : Pre-stim'], 'Interpreter', 'none');
    
    % ---------- LEFT COLUMN: Healthy vs PD_OFF ----------
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'total_2', 'Total', 1, col_healthy, col_pd_off);
    
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'aperiodic_2', 'Aperiodic', 3, col_healthy, col_pd_off);
    
    plot_block(T, "Healthy", "PD_OFF", freqs, ...
        'periodic_2', 'Periodic', 5, col_healthy, col_pd_off);
    
    
    % ---------- RIGHT COLUMN: PD_ON vs PD_OFF ----------
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'total_2', 'Total', 2, col_pd_on, col_pd_off);
    
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'aperiodic_2', 'Aperiodic', 4, col_pd_on, col_pd_off);
    
    plot_block(T, "PD_ON", "PD_OFF", freqs, ...
        'periodic_2', 'Periodic', 6, col_pd_on, col_pd_off);
    
    
    % Save
    safe_area = strrep(area_name, ' ', '_');
    save_path = fullfile(save_dir, [safe_area '_PreStim']);
    
    exportgraphics(gcf, [save_path '.png'], 'Resolution', 300);
    savefig(gcf, [save_path '.fig']);

end

%% -------- Helper function --------
function plot_block(T, cond1, cond2, freqs, fieldname, title_str, subplot_idx, col1, col2)

    subplot(3,2,subplot_idx); hold on;
    
    % Extract valid rows for each condition
    data1 = extract_condition(T, cond1, fieldname);
    data2 = extract_condition(T, cond2, fieldname);
    
    % Compute mean and SD
    [m1, s1] = compute_stats(data1);
    [m2, s2] = compute_stats(data2);
    
    % Plot condition 1
    if ~isempty(m1)
        fill([freqs fliplr(freqs)], ...
             [m1+s1 fliplr(m1-s1)], ...
             col1, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        plot(freqs, m1, 'Color', col1, 'LineWidth', 2);
    end
    
    % Plot condition 2
    if ~isempty(m2)
        fill([freqs fliplr(freqs)], ...
             [m2+s2 fliplr(m2-s2)], ...
             col2, 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        plot(freqs, m2, 'Color', col2, 'LineWidth', 2);
    end
    
    title(title_str);
    xlabel('Frequency (Hz)');
    ylabel('Log Power');
    xlim([0 50]);
    
    legend([cond1 cond2], 'Location', 'best');
    grid on;
end


%% -------- Extract valid data --------
function data_mat = extract_condition(T, cond, fieldname)

    idx = T.Plot_x == cond;
    Tsub = T(idx,:);
    
    data_mat = [];
    
    for i = 1:height(Tsub)
        x = Tsub.(fieldname){i};
        
        if ~isempty(x) && isnumeric(x)
            data_mat = [data_mat; x]; %#ok<AGROW>
        end
    end
end


%% -------- Compute mean + SD --------
function [m, s] = compute_stats(data_mat)

    if isempty(data_mat)
        m = [];
        s = [];
        return;
    end
    
    m = mean(data_mat, 1, 'omitnan');
    s = std(data_mat, 0, 1, 'omitnan');
end