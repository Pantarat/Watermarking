clear

[audioData,fs] = audioread("Audio_Source/sample_data.wav");

cd Tools/

[SMR, min_threshold_subband, frame_psd_dBSPL, masking_threshold,max_local,tonal,X_tm_avant,X_nm_avant,X_tm,X_nm]...
    = MPEG1_psycho_acoustic_model1JK(audioData(1:512,1));

masking_threshold

cd ..