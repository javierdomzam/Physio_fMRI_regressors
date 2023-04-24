% This function saves the physiological data for each subject in the given
% subject list. It loops through all the subjects in the list and extracts
% the physiological data for each run. It saves the extracted data in
% separate text files for each run. The saved data include pulse and
% respiratory signals, and fMRI triggers. The function uses
% readCMRRPhysio() function to extract physiological data from .dcm files.

function save_physio(subject_list)

p_c=subject_list % p_c is a list of subject IDs
pos=1; % not used in this function
% delete 3 volumes
%delete_timestamps=(400*700); % not used in this function

dbstop if error % Set a debug breakpoint in case of errors

for sn=1:length(p_c)
    sub=num2str(p_c(sn),'%02d');
    p_code=sprintf('sub-%s',sub); % Create subject code
    
    
    dir_save = sprintf('your_dir',p_code); % Set save directory for Windows
    
    addpath(dir_save); % Add directory to the path
    disp(p_code);
    
    for i=[1 2 3 4] % loop through each run
        
        data_name = sprintf('physioLog_%i.dcm',i); % Set name of the .dcm file
        
        physio = readCMRRPhysio(data_name, 1); % Read the physiological data from the .dcm file
        file_name = sprintf('%s_physio_run%i',p_code,i); % Set the name of the output file
        save (fullfile(dir_save, file_name), 'physio') % Save the physiological data in a .mat file
        
        acq_all = (physio.ACQ); % Extract the acquisition signal
        n=find(physio.ACQ==1); % Find the start of the first volume
        run_start=n(2); % Find the start of the run
        pulse=double(physio.PULS); % Extract the pulse signal
        acq = find(physio.ACQ==1); % Extract the acquisition signal
        
        % Clean up the pulse signal
        pulse_x = 1:length(pulse);
        pulse_xi = 1:length(pulse);
        pulse_zs = pulse==0; % Zeros locations
        pulse(pulse_zs) = [];
        pulse_x(pulse_zs)=[];
        pulse_clean = interp1(pulse_x, pulse, pulse_xi);
        pulse_pnm=pulse_clean';
        pulse_clean(1:run_start+2400)=[];
        pulse_name = sprintf('%s_pulse_data_run%i.txt',p_code,i);
        writematrix(pulse_clean, fullfile(dir_save,pulse_name)); % Save the cleaned pulse signal in a text file
        
        % Clean up the respiratory signal
        resp=double(physio.RESP);
        resp_x = 1:length(resp);
        resp_xi = 1:length(resp);
        resp_zs = resp==0; % Zeros locations
        resp(resp_zs) = [];
        resp_x(resp_zs)=[];
        resp_clean = interp1(resp_x, resp, resp_xi);
        resp_pnm=resp_clean';
        resp_clean(1:run_start+2400)=[];
        resp_name = sprintf('%s_resp_data_run%i.txt',p_code,i);
        %dlmwrite(resp_name,resp_clean,'\t');
        writematrix(resp_clean, fullfile(dir_save,resp_name));
        
        
        all_physio=[pulse_clean' resp_clean'];
        name = sprintf('%s_physio_data_run%i.txt',p_code,i);
        dlmwrite(fullfile(dir_save,name),all_physio,'delimiter', '\t','precision','%.5f');
        %writematrix(all_physio, fullfile(dir_save,name),'Delimiter' ,' ');
        
        mri_trigger=physio.SliceMap(1,:,1)';
        mri_trigger=double(mri_trigger);
        %mri_trigger(1:4,:)=[];
        mri_trigger(mri_trigger==0) = [];
        a=zeros(length(physio.PULS),1);
        a(mri_trigger,:) = 1;
        
        
        all_physio_PNM=[pulse_pnm resp_pnm a];
        
        num_trigger=sum((all_physio_PNM(:,3)==1));
        text=sprintf('fMRI trigger run%i = %i',i,num_trigger);
        disp(text);
        name = sprintf('%s_physio_data_run%i_PNM.txt',p_code,i);
        dlmwrite(fullfile(dir_save,name),all_physio_PNM,'delimiter', '\t');%',precision','%.0f'
        
    end
    
    close all
end
end