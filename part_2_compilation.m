clc, clearvars, close all;

% Load MAIN results
addpath('D:/NT lab/Publication_Project/results/feb_end')

load('part_1_compilation.mat');   % loads variable: results


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PART 2 
% Feature extraction. These include ...
% 1. Peak freq 2. Power at peak freq 3. Normalised power at peak freq
% (1,2,3 correspond to periodic power spectrum)
% 4. Aperiodic exponent 5. Aperiodic offset 6. Total power across spectrum
% 7. Total Periodic power across spectrum (percentage)
% 8. Total aperiodic power across spectrum (percentage)

%%

% PART 2A. (Feature extraction from POST STIM DATA)
% 1. Peak_freq_extraction 2. p_a_pf extraction 4. Aperiodic exponent
% 5. Aperiodic offset

% Preallocate
n = height(results);
results.Peak_freq_fft_1 = nan(n,1);
results.Power_a_pf_1 = nan(n,1);
results.Aper_exp_1 = nan(n,1);
results.Aper_offset_1 = nan(n,1);

for i = 1:n
    fooof_out = results.FOOOF_output_1 {i};
    if isempty(results.Induced_ps_avg_1{i}) || isempty(fooof_out)
    continue;
    end

    % Aperiodic parameters (vector)
    if isfield(fooof_out, 'aperiodic_params')
    results.Aper_exp_1 (i) = fooof_out.aperiodic_params (1); 
    results.Aper_offset_1 (i) = fooof_out.aperiodic_params (2); 
    end

    % Peak parameters (Nx3)
    peaks = fooof_out.peak_params;
    if ~isempty(peaks)
    [max_pow, idx] = max(peaks(:,2));
    results.Power_a_pf_1 (i) = max_pow;
    results.Peak_freq_fft_1 (i) = peaks(idx,1);
    end

end

% Feature 6, 7 and 8    and 3. 
for i = 1:n

    if ~isempty(results.FOOOF_output_1{i})
    
        F = results.FOOOF_output_1{i};
    
        psd_lin = 10 .^ F.fooofed_spectrum;
        ap_lin  = 10 .^ F.ap_fit;
        
        auc_psd  = sum(psd_lin, 'omitnan');
        auc_aper = sum(ap_lin,  'omitnan');
        auc_per  = sum(psd_lin - ap_lin, 'omitnan');
    
        if auc_psd > 0
            results.auc_psd_1(i) = log10(auc_psd);
        else
            results.auc_psd_1(i) = NaN;
        end
    
        if auc_aper > 0
            results.auc_aper_1(i) = log10(auc_aper);
        else
            results.auc_aper_1(i) = NaN;
        end
    
        if auc_per > 0
            results.auc_per_1 (i) = log10(auc_per);

            results.norm_papf_1 (i) = 10 ^ results.Power_a_pf_1 (i) / auc_per;
        else
            results.auc_per_1 (i) = NaN;
            results.norm_papf_1 (i) = NaN;
        end

    end

end

%%
% PART 2B. (Feature extraction from PRE STIM DATA/ BASELINE)
% 1. Peak_freq_extraction 2. p_a_pf extraction 4. Aperiodic exponent
% 5. Aperiodic offset

% Preallocate
n = height(results);
results.Peak_freq_fft_2 = nan(n,1);
results.Power_a_pf_2 = nan(n,1);
results.Aper_exp_2 = nan(n,1);
results.Aper_offset_2 = nan(n,1);

for i = 1:n
    fooof_out = results.FOOOF_output_2 {i};
    if isempty(results.Induced_ps_avg_2{i}) || isempty(fooof_out)
    continue;
    end

    % Aperiodic parameters (vector)
    if isfield(fooof_out, 'aperiodic_params')
    results.Aper_exp_2 (i) = fooof_out.aperiodic_params (1); 
    results.Aper_offset_2 (i) = fooof_out.aperiodic_params (2); 
    end

    % Peak parameters (Nx3)
    peaks = fooof_out.peak_params;
    if ~isempty(peaks)
    [max_pow, idx] = max(peaks(:,2));
    results.Power_a_pf_2 (i) = max_pow;
    results.Peak_freq_fft_2 (i) = peaks(idx,1);
    end

end

% Feature 6, 7 and 8    and 3. 
for i = 1:n

    if ~isempty(results.FOOOF_output_2{i})
    
        F = results.FOOOF_output_2{i};
    
        psd_lin = 10 .^ F.fooofed_spectrum;
        ap_lin  = 10 .^ F.ap_fit;
        
        auc_psd  = sum(psd_lin, 'omitnan');
        auc_aper = sum(ap_lin,  'omitnan');
        auc_per  = sum(psd_lin - ap_lin, 'omitnan');
    
        if auc_psd > 0
            results.auc_psd_2(i) = log10(auc_psd);
        else
            results.auc_psd_2(i) = NaN;
        end
    
        if auc_aper > 0
            results.auc_aper_2(i) = log10(auc_aper);
        else
            results.auc_aper_2(i) = NaN;
        end
    
        if auc_per > 0
            results.auc_per_2 (i) = log10(auc_per);

            results.norm_papf_2 (i) = 10 ^ results.Power_a_pf_2 (i) / auc_per;
        else
            results.auc_per_2 (i) = NaN;
            results.norm_papf_2 (i) = NaN;
        end

    end

end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% Initialize Patient_ID column
results.Patient_ID = repmat("", height(results), 1);

for i = 1:height(results)
    if ~isempty(results.f_Names{i})
        % Extract string between first and second underscore
        parts = split(results.f_Names{i}, '_');
        if length(parts) >= 2
            patient_id = parts{2};
            % Prepend 'H' or 'PD' based on f_Names content
            if contains(results.f_Names{i}, {'HC', 'HV'})
                results.Patient_ID{i} = ['H', patient_id];
            elseif contains(results.f_Names{i}, 'PD')
                results.Patient_ID{i} = ['PD', patient_id];
            else
                results.Patient_ID{i} = patient_id;
            end
        end
    end
end

% Initialize Plot_x column
results.Plot_x = repmat("", height(results), 1);

for i = 1:height(results)
    if ~isempty(results.f_Names{i})
        if strcmp(results.Disease_state{i}, 'Healthy')
            results.Plot_x{i} = 'Healthy';
        elseif strcmp(results.Disease_state{i}, 'PD')
            if strcmp(results.Drug_state{i}, 'OFF')
                results.Plot_x{i} = 'PD_OFF';
            else
                results.Plot_x{i} = 'PD_ON';
            end
        end
    end
end