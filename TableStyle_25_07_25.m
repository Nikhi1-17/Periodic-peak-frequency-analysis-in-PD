clc;
clearvars;

% Step 1: Initialize empty results table
results = table;
results.Names_original__mat = {};
results.Passed_sub_threshold = {};
results.f_Names = {};
results.Site = {};
results.Area = {};
results.Electrode = {};
results.Evoked_ts = {};
results.Induced_ts_trials_1 = {};
results.Induced_ts_trials_2 = {};
results.Induced_ps_trials = {};
results.Induced_ps_avg = {};

% Step 2: Define the folder paths
folderPaths = {
    '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data', 
    '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/PD_data'
};

% Step 3: Loop over each folder path
for f = 1:length(folderPaths)
    folderPath = folderPaths{f};

    % Step 4: List all files in the folder
    fileList = dir(folderPath);

    % Step 5: Loop through each file in the folder
    for k = 1:length(fileList)
        fileName = fileList(k).name;

        if endsWith(fileName, '.mat') && ...
           ~(startsWith(fileName, '._PD') || startsWith(fileName, '._HC') || startsWith(fileName, '._HV'))

            results.Names_original__mat{end+1, 1} = fileName;
        end
    end
end

% Step 6: Now loop over results and fill Passed_sub_threshold n sham row by row
nRows = height(results);

for i = 1:nRows
    currentName = results.Names_original__mat{i};

    if ~contains(currentName, '_80') && ~contains(currentName, 'sham')
        results.Passed_sub_threshold{i} = currentName;
    end
end

for i = 1:nRows 
    currentName = results.Passed_sub_threshold{i};
    
    if ~isempty(currentName)
        results.f_Names{i} = erase(currentName, '__final_avref_Fieldtrip.mat');
    end
end


%% 

% Comparing to Giorgio data
% Step 1: Import the Excel file as a table
addpath ('/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data/analysis_folder/26_07_25_work')
z = readtable('giorgio_orientation.xlsx'); 

% Step 2: Loop over each entry in f_Names
% Sites are different for less and more (FIX)

%for i = 1:height(results)
%    fname = results.f_Names{i};
    
 %   if ~isempty(fname)
  %      for j = 1:height(z)
   %         name_from_z = z.Name{j};
    %        
     %       if contains(fname, name_from_z) && contains(fname, "M1_more")
      %          results.Site{i} = z.Site{j};
       %     elsif contains(fname, name_from_z) && contains(fname, "M1_less")
        %        non_dom = ["L", "R"] - z.Site{j};
         %       results.Site{i} = non_dom (1);
%
 %               break;  % stop after first match
  %          end
        %end
   % end
%end

% for i = 1:height(results)
%     fname = results.f_Names{i};
% 
%     if ~isempty(fname)
%         for j = 1:height(z)
%             name_from_z = strtrim(z.Name{j});
%             dominant_site = strtrim(z.Site{j});
% 
%             if contains(fname, name_from_z)
%                 if contains(fname, "M1_more")
%                     results.Site{i} = z.Site{j};
%                     break;  % done after match
%                 elseif contains(fname, "M1_less")
%                     Assign the non-dominant side
%                     if contains(z.Site{j}, 'L')
%                         results.Site{i} = 'R';
%                     elseif contains(z.Site{j}, 'R')
%                         results.Site{i} = 'L';
%                     else
%                         warning('Unknown dominant side at row %d', j);
%                     end
%                     break;  % done after match
%                 end
%             end
%         end
%     end
% end

% Loop through results
for i = 1:height(results)
    fname = results.f_Names{i};

    if ~isempty(fname)
        % Extract subject ID, e.g., 'PD_104' from 'PD_104_OFF_M1more_...'
        tokens = regexp(fname, '(PD_\d+)', 'tokens');
        if ~isempty(tokens)
            subj_id = tokens{1}{1};

            % Find row in z that matches this subject
            idx = strcmp(z.Name, subj_id);
            if any(idx)
                dominant_side = z.Site{idx};

                % Assign site based on M1more / M1less
                if contains(fname, 'M1more', 'IgnoreCase', true)
                    results.Site{i} = dominant_side;
                elseif contains(fname, 'M1less', 'IgnoreCase', true)
                    % Flip side
                    if strcmpi(dominant_side, 'L')
                        results.Site{i} = 'R';
                    elseif strcmpi(dominant_side, 'R')
                        results.Site{i} = 'L';
                    end
                else
                    results.Site{i} = ''; % No M1 label
                end
            end
        end
    end
end

% Save the updated table
writetable(results, 'Proc_Peak_Freq_31_07_25_with_Site.xlsx');

%%


% Step 3: Identifying site for M healthy
for i = 1:104 % No. of healthy subjects
    name = results.f_Names{i};

    if ~isempty(name) %&& ischar(name)  % or use isstring(name) for string arrays
        if contains(name, "HV") || contains(name, "HC")
            if contains(name, "M1less")
                results.Site{i} = "R";
            elseif contains(name, "M1more")
                results.Site{i} = "L";
            end
        end
    end
end

%%
% Step 4: Electrodes
for i = 1:length(results.Names_original__mat)
    fname = results.f_Names{i};

    if ~isempty(fname)
        sname = results.Names_original__mat{i};

        for f = 1:length(folderPaths)
            folderPath = folderPaths{f};
            fileList = dir(folderPath);

            for k = 1:length(fileList)
                fileName = fileList(k).name;

                if strcmp(sname, fileName)
                    % Assume fileName is a .mat file in the folderPath
                    filePath = fullfile(folderPath, fileName);
                    
                    data = load(filePath); % Why go through the hassle of loading this
                    % when you are not using it in the loop?

                    % Access the label field (assumed to be data.label)
                    % and assign electrode based on site or fname substrings
                    
                    % You didn't access the label field. You just used the
                    % site name to assign electrode name. This can be done
                    % outside of loop.
                    site = results.Site{i};

                    if strcmp(site, "L")
                        results.Electrode{i} = "C3";
                    elseif strcmp(site, "R")
                        results.Electrode{i} = "C4";
                    else
                        if contains(fname, "SMAproper")
                            results.Electrode{i} = "Cz";
                        elseif contains(fname, "SMA")
                            results.Electrode{i} = "FCz";
                        elseif contains(fname, "SPL")
                            results.Electrode{i} = "Pz";
                        end
                    end

                    break; % Stop searching after finding the match
                end
            end
        end
    end
end

%%

%Step 5
% Suggestion: Add folder path column to the table. You already have
% filename. You can just collate those to load the required files directly
% in one loop. No need to run 3 nested loops.

for i = 1:height(results)
    fname = results.f_Names{i};
    if ~isempty(fname)
        sname = results.Names_original__mat{i};  % Note: only 2 underscores
        for f = 1:length(folderPaths)
            folderPath = folderPaths{f};
            fileList = dir(fullfile(folderPath, '*.mat'));

            for k = 1:length(fileList)
                fileName = fileList(k).name;

                if strcmp(sname, fileName)
                    filePath = fullfile(folderPath, fileName);
                    all_fields = load (filePath);
                    fields = fieldnames(all_fields);       
                    tl_data = all_fields.(fields{5});
                    data = all_fields. (fields{3});

                    if ~isempty(results.Electrode{i})
                        targetElec = results.Electrode{i};
                        all_elec = tl_data.label;

                        % Get index of electrode
                        l_index = find(strcmp(all_elec, targetElec));

                        if ~isempty(l_index)
                            % Evoked time series
                            results.Evoked_ts{i} = tl_data.avg(l_index, :);

                            % Induced (trial-based) time series
                            nTrials = length(data.trial);
                            ts_elec_tri = cell(1, nTrials);
                            for nt = 1:nTrials
                                trialMat = data.trial{1, nt};
                                ts_elec_tri{1, nt} = trialMat(l_index, :);
                            end
                            
                            i_ts_elec_tri = cell (1, nTrials);
                            %i_ts_elec_tri_1 = cell (1, nTrials);
                            %i_ts_elec_tri_2 = cell (1, nTrials);

                            for tr = 1: nTrials 
                                % Subtract evoked response from each trial's signal at this electrode
                                i_ts_elec_tri{1, tr} = ts_elec_tri{1, tr} - results.Evoked_ts{i};
                                
                                % Extract the time vector for this trial
                                timee = data.time{1, tr};
                                
                                % Logical index for 15 ms to 500 ms
                                % post-stimulus || n for 20ms to 200ms
                                tidx = timee >= 0.015 & timee <= 0.5;
                                tidx_2 = timee >= 0.02 & timee <= 0.2;
                                
                                % Restrict induced time series to post-stimulus window
                                i_ts_elec_tri_1{1, tr} = i_ts_elec_tri{1, tr}(tidx); %Trimming
                                i_ts_elec_tri_2{1, tr} = i_ts_elec_tri{1, tr}(tidx_2); %Trimming 2

                            end

                            results.Induced_ts_trials_1{i} = i_ts_elec_tri_1;
                            results.Induced_ts_trials_2{i} = i_ts_elec_tri_2;
                          
                        end
                    end
                end
            end
        end
    end
end

%% 
% Step 6 - Performing FFT of Induced

fs = 1000;

for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_1 {i})
        nTrials = length(results.Induced_ts_trials_1 {i}); % Number of trials

        results.Induced_ps_trials{i} = cell(1, nTrials); % Preallocate

        for j = 1:nTrials
            ts = results.Induced_ts_trials_1 {i}{j}; % 1xN vector
            [freqs, power_spectrum] = compute_power_spectrum(ts, fs);
            results.Induced_ps_trials{i}{j} = [freqs(:)'; power_spectrum(:)'];

        end
    end
end



%%
% Step 7
for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_1 {i})
        nTrials = length(results.Induced_ts_trials_1 {i}); % Number of trials

        % Initialize with zeros: 1 x N (N = number of frequency bins)
        results.Induced_ps_avg{i} = zeros(1, size(results.Induced_ps_trials{i}{1}, 2));

        for j = 1:nTrials
            % Add the second row (power spectrum) from each trial
            results.Induced_ps_avg{i} = results.Induced_ps_avg{i} + results.Induced_ps_trials{i}{j}(2, :);
        end

        % Average by dividing by number of trials
        results.Induced_ps_avg{i} = results.Induced_ps_avg{i} / nTrials;
    end
end

%%
% Step 8
% Settings
addpath('/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data/analysis_folder/FOOOF/');
fs = 1000;
settings.peak_width_limits = [1, 8];
settings.max_n_peaks = 6;
settings.min_peak_height = 0.1;
settings.peak_threshold = 2;
settings.aperiodic_mode = 'fixed';
settings.verbose = false;

% Initialize new columns
results.FOOOF_output = cell(height(results), 1);
results.Is_it_flat = cell(height(results), 1);  % You can later change to logical if you want

% Loop through each subject
for i = 1:height(results)
    if ~isempty(results.Induced_ps_avg{i})
        % Get frequency vector from first trial
        freqs = results.Induced_ps_trials{i}{1}(1, :);
        
        % Get average power spectrum
        power_spectrum = results.Induced_ps_avg{i}(1, :);
        
        % Run FOOOF and store the result
        fm = fooof(freqs, power_spectrum, [4, 45], settings, true);
        results.FOOOF_output{i} = fm;
    end
end
%%
% Step: Is it flat ?
% Add the new columns to the results table
results.Dom_freq_fft = cell(height(results), 1);

for i = 1:height(results)
    if ~isempty(results.Induced_ps_avg{i})
        
        % Extract aperiodic parameters from FOOOF output
        aper = results.FOOOF_output{i}.aperiodic_params;  % 1x2 vector
        aper_slope = aper(1, 2);
        
        if aper_slope > 0.02
            results.Is_it_flat{i} = "No";
            
            % Extract peak characteristics
            peaks_char = results.FOOOF_output{i}.peak_params;  % Nx3 matrix
            peak_pow = peaks_char(:, 2)';  % Make it a row vector
            
            [max_pow, i_max_pow] = max(peak_pow);
            dom_peak_freq = peaks_char(i_max_pow, 1);
            
            results.Dom_freq_fft{i} = dom_peak_freq;
        else
            results.Is_it_flat{i} = "Yes";
        end
    end
end


%%
%Step: Morlet Wavelets
% REDOIN for MW-tcon

fs = 1000;

results.Morlet_tcon_ps_trials = cell(height(results), 1);
results.Morlet_tcon_ps_avg = cell(height(results), 1);

for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_2 {i})
        nTrials = length(results.Induced_ts_trials_2 {i}); % Number of trials

        results.Morlet_tcon_ps_trials{i} = cell(1, nTrials); % Preallocate

        for j = 1:nTrials
            ts = results.Induced_ts_trials_2 {i}{j}; % 1xN vector
            [power_spectrum, freqs] = morlet_power_spectrum (ts, fs, results.Induced_ps_trials {i}{1, j}(1, :));
            results.Morlet_tcon_ps_trials {i}{j} = [freqs(:)'; power_spectrum(:)'];

        end
    end
end

% Step avg-ing
for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_2 {i})
        nTrials = length(results.Induced_ts_trials_2 {i}); % Number of trials

        % Initialize with zeros: 1 x N (N = number of frequency bins)
        results.Morlet_tcon_ps_avg {i} = zeros(1, size(results.Morlet_tcon_ps_trials {i}{1}, 2));

        for j = 1:nTrials
            % Add the second row (power spectrum) from each trial
            results.Morlet_tcon_ps_avg{i} = results.Morlet_tcon_ps_avg{i} + results.Morlet_tcon_ps_trials{i}{j}(2, :);
        end

        % Average by dividing by number of trials
        results.Morlet_tcon_ps_avg{i} = results.Morlet_tcon_ps_avg{i} / nTrials;
    end
end

%%
% Initialize columns
results.Disease_state = cell(height(results), 1);
results.Drug_state = cell(height(results), 1);

% Loop through each row
for i = 1:height(results)
    fname = results.f_Names{i};

    if ~isempty(fname)

        % Assign Site (order matters to avoid overwrites)
        if contains(fname, 'M1less')
            results.Area{i} = 'M1_rec';
        elseif contains(fname, 'M1more')
            results.Area{i} = 'M1_dom';
        elseif contains(fname, 'SMAproper')
            results.Area{i} = 'SMA';
        elseif contains(fname, 'SMA')
            results.Area{i} = 'pre_SMA';
        elseif contains(fname, 'SPL')
            results.Area{i} = 'SPL';
        end

        % Assign Drug State
        if contains(fname, 'ON')
            results.Drug_state{i} = 'ON';
        else
            results.Drug_state{i} = 'OFF';
        end

        % Assign Disease State
        if contains(fname, 'PD')
            results.Disease_state{i} = 'PD';
        else
            results.Disease_state{i} = 'Healthy';
        end

    end
end


%%
% Dom_freq_extr_MW

% Add the new column to the results table
results.Dom_freq_mw = cell(height(results), 1);

for i = 1:height(results)
    % Check if the entry is not empty
    if ~isempty(results.Morlet_tcon_ps_avg{i})
        % Find the maximum value and its index
        [big, ind] = max(results.Morlet_tcon_ps_avg{i});
        
        % Access the corresponding frequency from the Morlet_tcon_ps_trials row vector
        freq_row = results.Morlet_tcon_ps_trials{i, 1}{1, 1}(1, :);
        dom_freq = freq_row(ind);
        
        % Store the dominant frequency
        results.Dom_freq_mw{i} = dom_freq;
    end
end

%%
%Plotting
methods_list = {'Dom_freq_fft', 'Dom_freq_mw'};
areas_list = {'M1_dom', 'M1_rec', 'SMA', 'pre_SMA', 'SPL'};

% Set save directory
save_dir = '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data/analysis_folder/26_07_25_work/Boxplots_3';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

for m = 1:length(methods_list)
    method_name = methods_list{m};

    for s = 1:length(areas_list)
        area = areas_list{s};
        
        % Initialize groups
        b_pd_on = [];
        b_pd_off = [];
        b_h = [];
        
        for i = 1:height(results)
            val = results.(method_name){i};
            if ~isempty(val) && isnumeric(val) && isfinite(val)
                if strcmp(results.Area{i}, area)
                %if strcmpi(results.Area{i}, site)  % Case-insensitive comparison

                    if strcmp(results.Disease_state{i}, 'PD') && strcmp(results.Drug_state{i}, 'ON')
                        b_pd_on(end+1) = val;
                    elseif strcmp(results.Disease_state{i}, 'PD') && strcmp(results.Drug_state{i}, 'OFF')
                        b_pd_off(end+1) = val;
                    elseif strcmp(results.Disease_state{i}, 'Healthy') && strcmp(results.Drug_state{i}, 'OFF')
                        b_h(end+1) = val;
                    end
                end
            end
        end

        % Prepare data and group labels
                all_data = [b_pd_on, b_pd_off, b_h];
        group = [repmat({'PD ON'}, 1, length(b_pd_on)), ...
                 repmat({'PD OFF'}, 1, length(b_pd_off)), ...
                 repmat({'Healthy'}, 1, length(b_h))];

        fprintf ("b_pd_on= %d b_pd_off= %d b_h= %d\n",length(b_pd_on), length(b_pd_off), length(b_h))
        
        % Plot
%         figure;
%         hold on
%         boxchart(categorical(group), all_data);
%         ylabel('freq');
%         ylim([4, 45]);
%         xlabel('Group');
%         if strcmp(method_name, 'Dom_freq_fft')
%     title_name = 'FFT';
% else
%     title_name = 'MW';
% end
% 
%         title([area, title_name], 'Interpreter', 'none');
        fprintf("This is area - %s and this is method - %s\n", site, method_name);
        disp (" ")


                % Plot
        figure;
        hold on

        % Draw box chart
        boxchart(categorical(group), all_data);

        % Overlay scatter points (with jitter)
        g = double(categorical(group));  % Convert group labels to numeric positions
        scatter(g + 0.1 * randn(size(g)), all_data, 40, 'filled', 'MarkerFaceAlpha', 0.6);

        % Axes and labels
        ylabel('Frequency (Hz)');
        ylim([4, 45]);
        xlabel('Group');

        % Title
        if strcmp(method_name, 'Dom_freq_fft')
            title_name = 'FFT';
        else
            title_name = 'MW';
        end

        title([area, ' - ', title_name], 'Interpreter', 'none');

        fprintf("This is area - %s and this is method - %s\n", area, method_name);
        disp(" ");

        % 
        % % Annotate sample sizes
        % y_max = max(all_data)*1.05;
        % text(1, y_max, ['n = ', num2str(length(b_pd_on))], 'HorizontalAlignment', 'center');
        % text(2, y_max, ['n = ', num2str(length(b_pd_off))], 'HorizontalAlignment', 'center');
        % text(3, y_max, ['n = ', num2str(length(b_h))], 'HorizontalAlignment', 'center');
        % 
        % % Compute Bonferroni-corrected p-values safely
        % p1 = safe_ttest2(b_pd_on, b_pd_off);
        % p2 = safe_ttest2(b_pd_on, b_h);
        % p3 = safe_ttest2(b_pd_off, b_h);
        % pvals = min([p1, p2, p3] * 3, 1);  % Bonferroni correction
        % 
        % % Annotate p-values
        % y_text = y_max * 1.05;
        % text(1.5, y_text, ['p_{ON vs OFF} = ', sprintf('%.3f', pvals(1))], 'HorizontalAlignment', 'center');
        % text(2.0, y_text * 1.05, ['p_{ON vs H} = ', sprintf('%.3f', pvals(2))], 'HorizontalAlignment', 'center');
        % text(2.5, y_text * 1.1, ['p_{OFF vs H} = ', sprintf('%.3f', pvals(3))], 'HorizontalAlignment', 'center');
        % 
        % % Save the figure
        % saveas(gcf, fullfile(save_dir, ['Boxplot_', method_name, '_', area, '.png']));
        close(gcf)  % Optional: close to avoid too many open figures
    end
end
%%
% -------- Helper function --------
% function p = safe_ttest2(x, y)
%     if isempty(x) || isempty(y) || ~isnumeric(x) || ~isnumeric(y)
%         p = NaN;
%         return;
%     end
%     x = x(~isnan(x) & isfinite(x));
%     y = y(~isnan(y) & isfinite(y));
%     if isempty(x) || isempty(y)
%         p = NaN;
%     else
%         try
%             [~, p] = ttest2(x, y);
%         catch
%             p = NaN;
%         end
%     end
% end


%%
% New plotting
% Plotting
methods_list = {'Dom_freq_fft', 'Dom_freq_mw'};
areas_list = {'M1_dom', 'M1_rec', 'SMA', 'pre_SMA', 'SPL'};

% Set save directory
save_dir = '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data/analysis_folder/26_07_25_work/Boxplots_3';
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

for m = 1:length(methods_list)
    method_name = methods_list{m};

    for s = 1:length(areas_list)
        area = areas_list{s};

        % Initialize groups
        b_pd_on = [];
        b_pd_off = [];
        b_h = [];

        for i = 1:height(results)
            val = results.(method_name){i};
            if ~isempty(val) && isnumeric(val) && isfinite(val)
                if strcmp(results.Area{i}, area)
                    if strcmp(results.Disease_state{i}, 'PD') && strcmp(results.Drug_state{i}, 'ON')
                        b_pd_on(end+1) = val;
                    elseif strcmp(results.Disease_state{i}, 'PD') && strcmp(results.Drug_state{i}, 'OFF')
                        b_pd_off(end+1) = val;
                    elseif strcmp(results.Disease_state{i}, 'Healthy') && strcmp(results.Drug_state{i}, 'OFF')
                        b_h(end+1) = val;
                    end
                end
            end
        end

        % Prepare data and group labels
        all_data = [b_pd_on, b_pd_off, b_h];
        group = [repmat({'PD ON'}, 1, length(b_pd_on)), ...
                 repmat({'PD OFF'}, 1, length(b_pd_off)), ...
                 repmat({'Healthy'}, 1, length(b_h))];

        fprintf("b_pd_on = %d | b_pd_off = %d | b_h = %d\n", ...
            length(b_pd_on), length(b_pd_off), length(b_h));

        % Electrode selection based on area
        if strcmp(area, 'SPL')
            etrode = 'Pz';
        elseif strcmp(area, 'SMA')
            etrode = 'FCz';
        elseif strcmp(area, 'SMAproper')
            etrode = 'Cz';
        else
            etrode = 'C3 or C4';
        end

        % Title name from method
        if strcmp(method_name, 'Dom_freq_fft')
            title_name = 'FFT';
        else
            title_name = 'MW';
        end

        % Plot
        figure;
        hold on

        % Draw box chart
        boxchart(categorical(group), all_data);

        % Overlay scatter points (with jitter)
        g = double(categorical(group));  % Convert group labels to numeric positions
        scatter(g + 0.1 * randn(size(g)), all_data, 40, 'filled', 'MarkerFaceAlpha', 0.6);

        % Axes and labels
        ylabel('Frequency (Hz)');
        ylim([4, 45]);
        xlabel('Group');

        % Title with electrode
        title([area, ' - ', title_name, ' - ', etrode], 'Interpreter', 'none');

        % Annotate number of data points above each group
        group_names = {'PD ON', 'PD OFF', 'Healthy'};
        counts = [length(b_pd_on), length(b_pd_off), length(b_h)];
        for k = 1:length(group_names)
            text(k, 44.5, ['n = ', num2str(counts(k))], ...
                'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        end

        % Save the figure
        % saveas(gcf, fullfile(save_dir, [method_name '_' area '_boxplot.png']));
        close;

        fprintf("This is area - %s and this is method - %s\n", area, method_name);
        disp(" ");
    end
end


%%
%Functions
 function [freqs, power_spectrum] = compute_power_spectrum(raw_ts, fs)
% Computes the power spectrum (1–45 Hz) of a 1 x N time series using FFT
%
% Inputs:
%   raw_ts - 1 x N vector (time series data from one electrode)
%   fs     - Sampling frequency in Hz
%
% Outputs:
%   freqs           - 1 x M vector of frequencies (1–45 Hz)
%   power_spectrum  - 1 x M vector of power values (absolute, not log-transformed)

    % Ensure it's a row vector
    raw_ts = raw_ts(:)';  

    ns = size(raw_ts, 2);              % Number of samples
    fft_result = fft(raw_ts, [], 2);   % FFT along time dimension
    power = abs(fft_result).^2 / ns;   % Power spectrum

    % Keep only positive frequencies (1-sided)
    P1 = power(1:ns/2 + 1);
    P1(2:end-1) = 2 * P1(2:end-1);     % Double power except DC and Nyquist

    % Frequency vector
    f = (0:ns/2)*(fs/ns);

    % Select 1–45 Hz
    sel = f >= 1 & f <= 45;
    freqs = f(sel);
    power_spectrum = P1(sel);
end

function [power_spectrum, freqs] = morlet_power_spectrum(data, fs, freqs)
%MORLET_POWER_SPECTRUM Computes Morlet wavelet power across specified frequencies
%
%   INPUTS:
%       data         - time series data (1D array)
%       time_vector  - corresponding time stamps in seconds (same length as data)
%       fs           - sampling frequency in Hz
%       freqs        - vector of frequencies to analyze (e.g., 1:45)
%
%   OUTPUTS:
%       power_spectrum - power summed across time for each frequency
%       freqs          - same as input, returned for reference

width = 3.5; % number of cycles in wavelet
n_freqs = length(freqs);
n_time = length(data);
power_spectrum = zeros(1, n_freqs);

for fi = 1:n_freqs
    f = freqs(fi);
    
    % Standard deviation of Gaussian envelope
    s = width / (2 * pi * f);
    
    % Time vector for wavelet: ±3 std devs
    t = -3*s : 1/fs : 3*s;
    
    % Complex Morlet wavelet
    wavelet = exp(2*1i*pi*f*t) .* exp(-t.^2 / (2*s^2));
    
    % Normalize wavelet to preserve power
    wavelet = wavelet / sqrt(sqrt(pi) * s);
    
    % Convolve signal with wavelet
    conv_result = conv(data, wavelet, 'same');
    
    % Power spectrum (magnitude squared)
    power = abs(conv_result).^2;
    
    % Sum across time
    power_spectrum(fi) = sum(power);
end
end




%%

% num_PD_OFF = sum(strcmp(results.Drug_state, 'OFF') & strcmp(results.Disease_state, 'PD') & strcmp(results.Site, 'M1_dom'));
% num_PD_ON = sum(strcmp(results.Drug_state, 'ON') & strcmp(results.Disease_state, 'PD') & strcmp(results.Site, 'M1_dom'));
% num_HC = sum(strcmp(results.Drug_state, 'OFF') & strcmp(results.Disease_state, 'Healthy') & strcmp(results.Area, 'M1_dom'));


%num_PD_OFF_idx = find(strcmp(results.Drug_state, 'OFF') & strcmp(results.Disease_state, 'PD') & strcmp(results.Site, 'M1_dom'));
%num_PD_ON_idx = find(strcmp(results.Drug_state, 'ON') & strcmp(results.Disease_state, 'PD') & strcmp(results.Site, 'M1_dom'));
