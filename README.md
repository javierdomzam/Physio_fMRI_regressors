# Physiological Regressors for fMRI Data
This bash script creates physiological regressors for fMRI data using FSL tools. The physiological noise in the fMRI data is regressed out to improve the signal-to-noise ratio and the quality of fMRI data.

# Requirements
FSL tools

Matlab

# Directory Structure

data_dir: Directory containing the fMRI data and physiological data extracted from DICOM files.
code_dir: Directory containing the scripts for physiological noise correction.
fsl_dir: Directory containing the FSL tools.

# Usage
Set the directory paths for data_dir, code_dir, and fsl_dir in the script.
Specify the subject IDs in the subject_list array.

Run the script in the terminal:
``` bash
bash create_physio_regressors.sh
``` 
# Workflow
1. Extract the physiological data from DICOM files for each subject using save_physio function in MATLAB.
2. Create a directory to store the physiological noise matrices for each run of fMRI data.
3. For each run of fMRI data, remove the first three volumes, as they may contain artifacts, and store the remaining volumes in a new file.
4. Prepare the physiological data file for PNM (Physiological Noise Modeling) using fslFixText.
5. Run PNM stage 1 to obtain the physiological noise matrices for each run.
6. Run popp to obtain the physiological noise matrices for each run with slice-timing correction and smoothing.
7. Use pnm_evs to create the event files for each run using the physiological noise matrices.
8. Save the list of event files for each run in a text file to use in fMRI analysis.
