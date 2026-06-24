%%%%%
%%%         Part 1
%%%%%

% This is a consolidation of all my earlier codes. 
% I import data 
% we divide trial into two epochs - before stim and post stim
%     for the post stim epoch 
%         I find fft for each trial --> avg power
%         from this power spectra we extract the ...
%             aperiodic features - exponenet and offset
%             periodic features - peak freq, power_at_peak_freq, norm._power at peak freq
% 
%             power distribution - i.e. what percentage of the total power resides in aperiodic power
%     for the pre stim data
%         I find the avg psd across diff trials for the same subject (within the same time period)
        
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is part 1 
% Output of this code - The results table which I has'nt been saved exclusively in the code
% After execution, the 'results' table has to be saved. I have saved it in
% the folder feb_end as a seperate file called part1_compilation.mat

clc, clearvars, close all;

%%%%%
% Step 1: Initialize empty results table
results = table;
results.Names_original__mat = {};
results.Passed_sub_threshold = {};
results.f_Names = {};
results.Site = {};
results.Area = {};
results.Electrode = {};
results.Evoked_ts = {};
results.Induced_ts_trials_1 = {}; % refers to the time window of 15 to 500 ms
results.Prestim_ts_trials = {}; % refers to the time window of less than 0 ms i.e. baseline 

%%%%%
% Step 2:
% Importing data onto the table
% The data also consists of sham and sub threshold stimulus. We remove them subsequently

folderPaths = {
    '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data', 
    '/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/PD_data'
};

% Loop over each folder path
for f = 1:length(folderPaths)
    folderPath = folderPaths{f};

    % List all files in the folder
    fileList = dir(folderPath);

    % Loop through each file in the folder
    for k = 1:length(fileList)
        fileName = fileList(k).name;

        if endsWith(fileName, '.mat') && ...
           ~(startsWith(fileName, '._PD') || startsWith(fileName, '._HC') || startsWith(fileName, '._HV'))

            results.Names_original__mat{end+1, 1} = fileName;
        end
    end
end

% Now loop over results and fill Passed_sub_threshold n sham row by row
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

%%%%%
% Step 3 Comparing to giorgio_orientation.xlsx to identify the site of
% stimulation, in the cases of motor cortex stmulation
addpath ('/home/giorgiodata/Documents/Giorgio_Leodori_TEP_data/HV_data/analysis_folder/26_07_25_work')
z = readtable('giorgio_orientation.xlsx'); 

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
% writetable(results, 'Proc_Peak_Freq_31_07_25_with_Site.xlsx');

%%

%%%%%
% Step 4: Assigning site of stim for healthy indv

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
% Step 5: Electrodes
for i = 1:height(results)

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

end

%%
%%%%%
% Step 6 :
% Noting down the time series for different time windows i.e. pre stim and post stim 15 to 500 ms
% Subsequently finding the induced time series (trial - evoked)

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
                                
                                % Logical index for 15 ms to 500 ms and
                                % -5ms to -490 ms

                                tidx = timee >= 0.015 & timee <= 0.5;
                                tidx_2 = timee <= -0.005 & timee >= -0.490;
                                
                                % Restrict induced time series to post-stimulus window
                                i_ts_elec_tri_1 {1, tr} = i_ts_elec_tri{1, tr}(tidx); %Trimming 1 corresponds to the post stim time window of interest
                                % Baseline
                                i_ts_elec_tri_2 {1, tr} = ts_elec_tri{1, tr}(tidx_2); %Trial data only for baseline / pre-stim

                            end

                            results.Induced_ts_trials_1{i} = i_ts_elec_tri_1;
                            results.Prestim_ts_trials{i} = i_ts_elec_tri_2;
                          
                        end
                    end
                end
            end
        end
    end
end

%%
%%%%%
% Step 7A :
% Finding the the FFT of induced data
results.Induced_ps_trials_1 = cell(height(results), 1);
results.Induced_ps_avg_1 = cell(height(results), 1);

fs = 1000;

for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_1 {i})
        nTrials = length(results.Induced_ts_trials_1 {i}); % Number of trials

        results.Induced_ps_trials_1{i} = cell(1, nTrials); % Preallocate

        for j = 1:nTrials
            ts = results.Induced_ts_trials_1 {i}{j}; % 1xN vector
            [freqs, power_spectrum] = compute_power_spectrum(ts, fs);
            results.Induced_ps_trials_1{i}{j} = [freqs(:)'; power_spectrum(:)'];

        end
    end
end

%%
% Step 8A
% Finding the avg power across the FFT's of all the trials
for i = 1:height(results)
    if ~isempty(results.Induced_ts_trials_1 {i})
        nTrials = length(results.Induced_ts_trials_1 {i}); % Number of trials

        % Initialize with zeros: 1 x N (N = number of frequency bins)
        results.Induced_ps_avg_1{i} = zeros(1, size(results.Induced_ps_trials_1{i}{1}, 2));

        for j = 1:nTrials
            % Add the second row (power spectrum) from each trial
            results.Induced_ps_avg_1{i} = results.Induced_ps_avg_1{i} + results.Induced_ps_trials_1{i}{j}(2, :);
        end

        % Average by dividing by number of trials
        results.Induced_ps_avg_1{i} = results.Induced_ps_avg_1{i} / nTrials;
    end
end

%%
% Step 9A
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
results.FOOOF_output_1 = cell(height(results), 1);

% Loop through each subject
for i = 1:height(results)
    if ~isempty(results.Induced_ps_avg_1{i})
        % Get frequency vector from first trial
        freqs = results.Induced_ps_trials_1{i}{1}(1, :);
        
        % Get average power spectrum
        power_spectrum = results.Induced_ps_avg_1{i}(1, :);
        
        % Run FOOOF and store the result
        fm = fooof(freqs, power_spectrum, [4, 45], settings, true);
        results.FOOOF_output_1{i} = fm;
    end
end

%%%
%%
% Redoing the analysis for the baseline data
%%%

%%%%%
% Step 7B :
% Finding the the FFT of induced data
results.Induced_ps_trials_2 = cell(height(results), 1);
results.Induced_ps_avg_2 = cell(height(results), 1);

fs = 1000;

for i = 1:height(results)
    if ~isempty(results.Prestim_ts_trials {i})
        nTrials = length(results.Prestim_ts_trials {i}); % Number of trials

        results.Induced_ps_trials_2{i} = cell(1, nTrials); % Preallocate

        for j = 1:nTrials
            ts = results.Prestim_ts_trials {i}{j}; % 1xN vector
            [freqs, power_spectrum] = compute_power_spectrum(ts, fs);
            results.Induced_ps_trials_2{i}{j} = [freqs(:)'; power_spectrum(:)'];

        end
    end
end

%%
% Step 8B
% Finding the avg power across the FFT's of all the trials
for i = 1:height(results)
    if ~isempty(results.Prestim_ts_trials {i})
        nTrials = length(results.Prestim_ts_trials {i}); % Number of trials

        % Initialize with zeros: 1 x N (N = number of frequency bins)
        results.Induced_ps_avg_2{i} = zeros(1, size(results.Induced_ps_trials_2{i}{1}, 2));

        for j = 1:nTrials
            % Add the second row (power spectrum) from each trial
            results.Induced_ps_avg_2{i} = results.Induced_ps_avg_2{i} + results.Induced_ps_trials_2{i}{j}(2, :);
        end

        % Average by dividing by number of trials
        results.Induced_ps_avg_2{i} = results.Induced_ps_avg_2{i} / nTrials;
    end
end

%%
% Step 9B
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
results.FOOOF_output_2 = cell(height(results), 1);

% Loop through each subject
for i = 1:height(results)
    if ~isempty(results.Induced_ps_avg_2{i})
        % Get frequency vector from first trial
        freqs = results.Induced_ps_trials_2{i}{1}(1, :);
        
        % Get average power spectrum
        power_spectrum = results.Induced_ps_avg_2{i}(1, :);
        
        % Run FOOOF and store the result
        fm = fooof(freqs, power_spectrum, [4, 45], settings, true);
        results.FOOOF_output_2{i} = fm;
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % PART 2 
% % Feature extraction. These include ...
% % 1. Peak freq   2. Power at peak freq   3. Normalised power at peak freq
% % (1,2,3 correspond to periodic power spectrum)
% % 4. Aperiodic exponent     5. Aperiodic offset     6. Total power across spectrum
% % 7. Total Periodic power across spectrum   
% % 8. Total aperiodic power across spectrum
% 
% 
% 
% %%
% % PART 2A. (Feature extraction from POST STIM DATA)
% 
% % 1. Peak_freq_extraction   2. p_a_pf extraction    4. Aperiodic exponent
% % 5. Aperiodic offset
% 
% % Preallocate
% n = height(results);
% 
% results.Peak_freq_fft_1 = nan(n,1);
% results.Power_a_pf_1    = nan(n,1);
% results.Aper_exp_1      = nan(n,1);
% results.Aper_offset_1    = nan(n,1);
% 
% for i = 1:n
% 
%     fooof_out = results.FOOOF_output_1 {i};
% 
%     if isempty(results.Induced_ps_avg_1{i}) || isempty(fooof_out)
%         continue;
%     end
% 
%     % Aperiodic parameters (vector)
%     if isfield(fooof_out, 'aperiodic_params')
%         results.Aper_exp_1 (i) = fooof_out.aperiodic_params (1); 
%         results.Aper_offset_1 (i) = fooof_out.aperiodic_params (2);         
%     end
% 
%     % Peak parameters (Nx3)
%     peaks = fooof_out.peak_params;
% 
%     if ~isempty(peaks)
%         [max_pow, idx] = max(peaks(:,2));
%         results.Power_a_pf_1 (i)   = max_pow;
%         results.Peak_freq_fft_1 (i) = peaks(idx,1);
%     end
% end
% 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
% FUNCTIONS
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
