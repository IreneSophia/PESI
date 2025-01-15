# PESI: Perception of nonverbal social interaction in autistic and non-autistic people

Autistic and non-autistic people differ in their perception and processing of social situations. However, it is still unclear on which differences these mechanisms are based. In this project, we will fill this gap by recording eye movements of autistic and non-autistic participants when observing non-verbal social interactions. Observing social interactions is an important source of information for social learning, and differences in the underlying mechanisms could therefore be an important cause of differences in social learning. This research project aims directly at understanding the mechanisms of one of the core symptoms of autism spectrum disorder (ASD).

Participants also completed tasks for an affiliated project (MAPC project). 

## Stimulus preparation

Part of the stimuli from Plank et al. (2023), *SciRep*., were used. Interpersonal synchrony based on Motion Energy Analysis was computed, and 10-second segments of the videos were chosen based on the following criteria: 

* only segments with total motion energy within 25 and 75 percentiles are used
* of these, each 4 segments of each dyad with the highest and lowest synchrony values based on the peaks

This resulted in a total of 64 10-second video segments of 8 dyads, always 4 high synchrony and 4 low synchrony. Half of the dyads consisted of one autistic and one non-autistic person, the other half of two non-autistic people. There were no differences in motion or synchrony between the two dyad types (see `prepro/stimevalPESI.Rmd')

The original videos were already processes with a filter such that only outlines of the interaction partners were visible. One person was always coloured in green and one in white. Therefore, we processed the frames by greyscaling them and changing the contrast to make both interaction partners coloured white and the outlines well visible. Additionally, the frames were rescaled by a factor of 1.75. 

## How to run this analysis

This repository includes scripts for the presentation of the paradigm, preprocessing of the data and analysis. Due to privacy issues, we only share preprocessed and anonymised data. Therefore, only the following analysis RMarkdown script can actually be run based on this repository: 

* `analysesPESI.Rmd`

 There are some absolute paths in these scripts within if statements. Downloading everything in this repository should ensure that these are not executed. 

We also share the models and the results of the simulation-based calibration. **Rerunning these, especially the SBC, can take days depending on the specific model.** Runtime of the scripts using the models and SBC shared in this repository should only take a few minutes. The scripts will create all relevant output that was used in the manuscript. If you need access to other data associated with this project or want to use the stimuli / paradigm, please contact the project lead (Irene Sophia Plank, 10planki@gmail.com). 

The `experiment` folder contains the scripts needed to present the experiment as well as the RMarkdown containing all information regarding the stimulus evaluation and selection. 

The `prepro` folder contains scripts used during preprocessing. All scripts contain information in the header regarding their use. 

### Versions and installation

Each html file contains an output of the versions used to run that particular script. It is important to install all packages mentioned in the html file before running a specific analysis file. Not all packages can be installed with `install.packages`, please consult the respective installation pages of the packages for more information. If the models are rerun, ensure a valid cmdstanr installation. 

For preprocessing of the eye tracking data, MATLAB R2023a was used. 

## Creation of areas of interest (AOIs) 

### Body AOIs

To create one matrix per dyad coding whether or not this pixel belongs to the body AOI, we used the script `combinePics_PESI.m`. This script sums up all frames of one dyad and resizes the matrix to fit the actual screen presentation during the experiment. Images were then adjusted in GIMP before being converted to csv files in MATLAB. 

### Head and hand AOIs

To track heads and hands across the video segments, we used DeepLabCut to get coordinates of landmarks for each frame. These were then visually inspected and corrected using `checkAOI_PESI.m`. This results in one csv file per video segment containing one row per frame with the pixel coordinates in the centre of the hands and the head. Based on these coordinates, we create frame-by-frame circle AOIs. 

## Variables

Data is shared in one RData `PESI_data.RData` file which can be read into R. This file contains the following data frames: 

`df`

* subID : anonymised subject ID which is consistent with subID in df.fix
* diagnosis : diagnostic status, either ASD for autistic adults or COMP for comparison group
* dyad : which dyad is shown in the video segment
* video : name of the video
* run : run number (1 or 2)
* trl : trial number (1 to 64)
* sync : whether the video displayed high or low IPS of motion
* rating : logged rating of this video (0 to 100)
* dyad.type : whether two non-autistic or one autistic and one non-autistic interaction partners are shown in the video (non-autistic or mixed)
* mot : overall motion energy in the video
* peak : continuous IPS of motion
* rating.confirmed: ratings usable for analysis (subjects confirmed their choice)
* thre : threshold in the perceptual simultaneity task
* steep : steepness of the curve in the perceptual simultaneity task

`df.fix`
* subID : anonymised subject ID which is consistent with subID in df.fix
* video : name of the video
* run : run number (1 or 2)
* eye : based on which eye the fixations were determined (l or r)
* trl : trial number (1 to 64)
* AOI : which AOI (head, hand, body exc. head and hand)
* n.total : total number of fixations in this video
* count : number of fixations for this AOI
* fix.total : sum of duration of all fixations in this video
* fix.dur : sum of duration of fixations on this AOI in this video
* sync : whether the video displayed high or low IPS of motion
* dyad : which dyad is shown in the video segment
* dyad.type : whether two non-autistic or one autistic and one non-autistic interaction partners are shown in the video (non-autistic or mixed)
* mot : overall motion energy in the video
* peak : continuous IPS of motion
* diagnosis : diagnostic status, either ASD for autistic adults or COMP for comparison group

`df.table`

* measurement : questionnaire or socio-demographic variable
* ASD : mean and standard errors or counts for the gender identities for the ASD group
* COMP : mean and standard errors or counts for the gender identities for the COMP group
* logBF10 : logarithmic Bayes Factor comparing the model including diagnosis to the null model

as well as `df.exc` (group and number of excluded participants), `df.incET` (group and number of included participants in the eye tracking analysis), `df.sht` (outcome of shapiro test for the demographic and questionnaire values) and the results of the contingency tables in `ct.full`.

## Project members

* Project lead LMU Munich: Irene Sophia Plank
* NEVIA lab PI LMU Munich: Christine M. Falter-Wagner
* Project members University of Cologne: Kai Vogeley, Ralf Tepest
* Afffiliated project members (MAPC project): Sonja Coenen, Yun Wai Foo

## Licensing

GNU GENERAL PUBLIC LICENSE
