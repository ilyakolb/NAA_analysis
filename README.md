GECI Neuronal Analysis 
======================================================================
2/20/2020

Processes and analyzes the results of GECI screening on the GENIE pipeline. Allows for manual curation of good/bad wells on a single-well basis. Creates mat structures for meta-analysis.

Author
======

Ilya Kolb  
GENIE Project  
Janelia Research Campus  
Howard Hughes Medical Institute  
kolbi@janelia.hhmi.org  

(original code by H Dana, TW Chen, D Kim)

Requirements
============

MATLAB 2017a+  
Image Processing Toolbox  


Installation
============
Add ./NAA_Curation, ./Neuronal_Assay_Analysis to MATLAB path  
Make sure nearline server is mounted if you need historical GCaMPs. Since all data is now on dm11, I disabled searching nearline.  


Running plates (run on Janelia LSF cluster)
===========
1. Download the week's imaging folder (e.g. 20170711_GCaMP96uf_raw) to dm11:\GECIScreenData\GECI_Imaging_Data\
2. using noMachine (or Putty or ssh) run `.startInteractiveMatlab 1` in terminal on LSF
3. Open run_plates.m. Add the plates from the week's imaging folder to the 'plates' variable, e.g. 'fullfile(GECI_imaging_dir, '20190702_GCaMP96uf_raw/P3a-20190617_GCaMP96uf')'. Edit other parameters as needed. Run.
4. Monitor job status on http://lsf1.int.janelia.org/cluster_status/

Compile data (run on PC)
===========
1. Open Z:\ilya\code\GECI_NAA_code_20191003\compile_results_main.m
2. Edit line: compile_results(fullfile(GECI_imaging_dir, '20191112_GCaMP96uf_analyzed'),'mngGECO','0') with the imaging folder

Curate data (run on PC)
===========
1. Open NAA_Curation/NAA_Curation.m and run. It will throw a warning which is OK. Go to the dates/plates you care about and follow the GUI to curate out bad wells
2. When done, click 'Create the data_all file' on top left menu bar. Pick 'GCaMP6uf', check 'Create pile_all_upto', and click OK. This may take several hours.
3. Compiled data is saved in dm11:\GECIScreenData\Analysis.


NAA_Curation shortcuts
===========
Plate view  
L,R,U,D keys: navigate between wells  
SPACE: go to well  
BACKSPACE: quick remove well and select reason  

Well view  
SPACE: go back  
BACKSPACE: remove well and select reason  


Notes
=====
- Run plates on LSF, compile data and curate on PC
- Not recently tested with any variants other than GCaMP96uf
- Also see instructions in run_plates.m
