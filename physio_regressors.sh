#!/bin/bash

# Print a message indicating the start of the job
echo JOB start
date

# Specify the list of subject IDs
declare -a subject_list=(59)
export subject_list

# Iterate over the list of subject IDs
for ID in ${subject_list[@]};
do
  # Construct the subject label
  SUBJ="sub-$ID"
  echo ${SUBJ}

  # Set the working directory to the location of the DICOM and physio data for this subject
  cd /path/to/dicom/and/physio/data

  # Run a MATLAB script to extract physio data
  matlab -nodisplay -r "save_physio($ID) ;quit;"

  # Set the working directory to the location of the fMRI data for this subject
  cd /path/to/fmri/data

  # Print a message indicating that physio data extraction is complete
  echo Physio data extraction completed

  # Create a directory to store the PNM data
  mkdir /path/to/fmri/data/${SUBJ}/physio/PNM

  # Set an environment variable to store the output directory for PNM processing
  export OUT_DIRECTORY="/path/to/fmri/data/${SUBJ}/physio/PNM"

  # Iterate over the four runs of the task
  for RUNID in 1 2 3 4;
  do
      # Set the working directory to the location of the fMRI data for this subject
      cd /path/to/fmri/data/${SUBJ}

      # Construct the label for this run
      RUN="run$RUNID"

      # Get the path to the physio data file for this run
      PHYSIO=`ls /path/to/fmri/data/${SUBJ}/physio/${SUBJ}_physio_data_${RUN}_PNM.txt`

      # Set the working directory to the location of the PNM data for this subject and run
      cd /path/to/fmri/data/${SUBJ}/physio/

      # Get the path to the fMRI data file for this run
      FUNC_O=`ls /path/to/fmri/data/${SUBJ}/func/${SUBJ}_task_${RUN}.nii.gz`

      # Delete the first three volumes of the fMRI data file
      volumn_num=$(fslnvols ${FUNC_O})
      final_vol="$((volumn_num-3))"
      echo ${RUN} final volumnes for PNM $final_vol
      fslroi ${FUNC_O} ${OUT_DIRECTORY}/${SUBJ}_taskPNM_${RUN} 3 ${final_vol}
      FUNC=`ls ${OUT_DIRECTORY}/${SUBJ}_taskPNM_${RUN}.nii.gz `

      # Prepare the physio data file for PNM processing
      /usr/local/fsl/bin/fslFixText ${PHYSIO} ${OUT_DIRECTORY}/${SUBJ}_physio_data_${RUN}_input.txt
      FIX_PHYSIO=`ls ${OUT_DIRECTORY}/${SUBJ}_physio_data_${RUN}_input.txt`

      # Run the PNM stage 1 script
      /usr/local/fsl/bin/pnm_stage1 -i ${FIX_PHYSIO} -o ${OUT_DIRECTORY}/${RUN} -s 400 --tr=2.0 --smoothcard=0.1 --smoothresp=0.1 --resp=2 --cardiac=1 --trigger=3

      # Create a directory to store the EV files for this run
      mkdir ${OUT_DIRECTORY}/${RUN}_EVs

      # Run the POPP script to create the physio regressors
      /usr/local/fsl/bin/popp -i ${OUT_DIRECTORY}/${SUBJ}_physio_data_${RUN}_input.txt  -o ${OUT_DIRECTORY} -s 400 --tr=2.0 --smoothcard=0.1 --smoothresp=0.1 --resp=2 --cardiac=1 --trigger=3

      /usr/local/fsl/bin/pnm_evs -i ${FUNC} -c ${OUT_DIRECTORY}/${RUN}_card.txt -r ${OUT_DIRECTORY}/${RUN}_resp.txt -o ${OUT_DIRECTORY}/${RUN}_EVs/${RUN} --tr=2.0 --oc=4 --or=4 --multc=0 --multr=0 --sliceorder=interleaved_up --slicedir=z

      # Make EV list for FEAT
      cd ${OUT_DIRECTORY}/${RUN}_EVs
      ls -d "${OUT_DIRECTORY}/${RUN}_EVs/"* > ${OUT_DIRECTORY}/${RUN}_evlist.txt
	  
	  
    done &

done

wait
echo JOB DONE
date