%% Set up path environments 
addpath(genpath('/Volumes/Luria/TBS-PM/scripts'));

%% Config for no desktop mode
spm defaults fmri
spm_jobman initcfg
spm_get_defaults('cmdline',true)


%% STUDY-SPECIFIC PARAMETERS
STUDY_DIR = '/Users/Broca/Desktop/PARTICIPANT_DATA/TBS';
ANALYSIS_DIR = '/Volumes/Luria/TBS-PM';
ROI_DIR = [ANALYSIS_DIR,'/ROIs'];
TR=2.5;
SESSIONS = {'PRE','POST'};


%% SUBJECTS
%SUBJECTS = make_subjects(STUDY_DIR);
SUBJECTS = num2cell(dlmread([ANALYSIS_DIR,'/scripts/pp_subjects.txt']))';
NSUBJECTS = length(SUBJECTS); 
NSESSIONS = length(SESSIONS);


%% SUBJECT LOOP FOR FILE ARRAYS
STRUCTURAL_FILE = cell(NSUBJECTS,1);
FUNCTIONAL_FILE = cell(NSUBJECTS,NSESSIONS);

for i = 1:NSUBJECTS
    subject = num2str(SUBJECTS{i});
    STRUCTURAL_FILE(i,1) = cellstr(fullfile(STUDY_DIR,subject,'PRE','T1.nii'));
    
    for j = 1:NSESSIONS
    SCAN = SESSIONS{j};
    FUNCTIONAL_FILE(i,j) = cellstr(fullfile(STUDY_DIR,subject,SCAN,'swuarest.nii'));
    REALIGN_FILE(i,j) = cellstr(fullfile(STUDY_DIR,subject,SCAN,'rp_arest.txt'));            
    OUT_FILE(i,j) = cellstr(fullfile(STUDY_DIR,subject,SCAN,'art_regression_outliers_uarest.mat'));
    end    
end


%% CREATES CONN BATCH STRUCTURE
clear batch;
cd(ANALYSIS_DIR);
cwd=pwd;
batch.filename=fullfile(ANALYSIS_DIR,'tbs_prepost_071818.mat');            % New conn_*.mat experiment name


%% SETUP BATCH   
batch.Setup.nsubjects=NSUBJECTS;
batch.Setup.RT=TR;


%% SETUP CONDITION STRUCTS
batch.Setup.conditions.names = SESSIONS;
batch.Setup.conditions.missingdata = 1;

for nsub=1:NSUBJECTS
    batch.Setup.conditions.onsets{1}{nsub}{1}=0;
    batch.Setup.conditions.onsets{1}{nsub}{2}=[];
    batch.Setup.conditions.onsets{2}{nsub}{2}=0;
    batch.Setup.conditions.onsets{2}{nsub}{1}=[];
    
    batch.Setup.conditions.durations{1}{nsub}{1}=Inf;
    batch.Setup.conditions.durations{1}{nsub}{2}=[];
    batch.Setup.conditions.durations{2}{nsub}{2}=Inf;
    batch.Setup.conditions.durations{2}{nsub}{1}=[];
end


%% POINT TO FUNCTIONAL IMAGES & 1ST LEVEL COVARIATES
batch.Setup.covariates.names={'realignment','outliers'};
batch.Setup.functionals=repmat({{}},[NSUBJECTS,1]);  
batch.Setup.covariates.files{1}=repmat({{}},[NSUBJECTS,1]);  
batch.Setup.covariates.files{2}=repmat({{}},[NSUBJECTS,1]);  
for nsub=1:NSUBJECTS
    for nses=1:NSESSIONS
        batch.Setup.functionals{nsub}{nses}{1}=FUNCTIONAL_FILE{nsub,nses};
        batch.Setup.covariates.files{1}{nsub}{nses}=REALIGN_FILE{nsub,nses}; 
        batch.Setup.covariates.files{2}{nsub}{nses}=OUT_FILE{nsub,nses}; 
    end 
end

%% POINT TO ANATOMICALS & MASKS
batch.Setup.voxelmask = 1;
batch.Setup.voxelmaskfile = fullfile(ROI_DIR,'stbsmask.nii');

for i = 1:NSUBJECTS
    subject = num2str(SUBJECTS{i});
    batch.Setup.structurals(i,1) = cellstr(fullfile(STUDY_DIR,subject,'PRE','wc0cT1.nii'));
    batch.Setup.masks.Grey(i,1) = cellstr(fullfile(STUDY_DIR,subject,'PRE','wc1cT1.nii'));
    batch.Setup.masks.White(i,1) = cellstr(fullfile(STUDY_DIR,subject,'PRE','wc2cT1.nii'));
    batch.Setup.masks.CSF(i,1) = cellstr(fullfile(STUDY_DIR,subject,'PRE','wc3cT1.nii'));
end   

%% SET UP ROIs
batch.Setup.rois.names = {'DMN-MTL','DMN-DMPFC','DMN-Core','FPN','SN','VLPFC'};

batch.Setup.rois.files{1} = {cellstr(fullfile(ROI_DIR,'DMN-MTL.nii'))};
batch.Setup.rois.multiplelabels(1) = 1;
batch.Setup.rois.files{2} = {cellstr(fullfile(ROI_DIR,'DMN-DMPFC.nii'))};
batch.Setup.rois.multiplelabels(2) = 1;
batch.Setup.rois.files{3} = {cellstr(fullfile(ROI_DIR,'DMN-Core.nii'))};
batch.Setup.rois.multiplelabels(3) = 1;
batch.Setup.rois.files{4} = {cellstr(fullfile(ROI_DIR,'FPN.nii'))};
batch.Setup.rois.multiplelabels(4) = 1;
batch.Setup.rois.files{5} = {cellstr(fullfile(ROI_DIR,'SN.nii'))};
batch.Setup.rois.multiplelabels(5) = 1;
batch.Setup.rois.files{6} = {cellstr(fullfile(ROI_DIR,'VLPFC.nii'))};
batch.Setup.rois.multiplelabels(6) = 1;


%% DECLARE OUTPUT FILES
batch.Setup.outputfiles(2) = 1;
batch.Setup.outputfiles(6) = 1;
batch.Setup.analyses = [1,2,3];


%% RUN SETUP 
batch.Setup.overwrite='Yes'; 
batch.Setup.done=1;


%% BATCH.Denoising PERFORMS DenoISING STEPS (confound removal & filtering) %!
batch.Denoising.filter = [0.008 0.1];
batch.Denoising.detrending = 1; 
batch.Denoising.confounds.names = {'White Matter','CSF','realignment','outliers','Effect of PRE','Effect of POST'};
batch.Denoising.confounds.dimensions = {10,10,[],[],1,1};
batch.Denoising.confounds.deriv = {0,0,1,0,1,1};


%% RUN DENOISING
batch.Denoising.overwrite = 'Yes';
batch.Denoising.done = 1;


%% FIRST-LEVEL ANALYSIS
batch.Analysis.measure=1; % Bivarite correlation


%% RUN ANALYSIS 
batch.Analysis.overwrite='Yes'; 
batch.Analysis.done=1;


%% Run all analyses                           
conn_batch(batch);



