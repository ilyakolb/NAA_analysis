# GECI Neuronal Analysis 

Processes and analyzes the results of GECI screening on the GENIE pipeline. Allows for manual curation of good/bad wells on a single-well basis. Creates mat structures for meta-analysis.

## Author

Ilya Kolb  
GENIE Project  
Janelia Research Campus  
Howard Hughes Medical Institute  
kolbi@janelia.hhmi.org  

(original code by H Dana, TW Chen, D Kim)

## Requirements

MATLAB 2017a+  
Image Processing Toolbox  
Access to Janelia high performance computing cluster
ilastik (see below)

## Installation
Download code to a location on your computer. If you will analyze plates using Janelia's LSF cluster, download the code to a location accessible by the cluster (e.g. dm11)  
 
On local machine add `GECI_NAA_code/NAA_Curation`, `GECI_NAA_code/Neuronal_Assay_Analysis`, `GECI_NAA_code/POI` to MATLAB path  
Make sure nearline server is mounted if you need historical GCaMPs. Since all data is now on dm11, I disabled searching nearline.  

### Installing ilastik
This code relies on [ilastik](https://www.ilastik.org/) to perform cell segmentation. Download ilastik and set the paths in `GECI_NAA_code/ilastik/run_ilastik.m` to point to your installation.  

## Starting MATLAB from Janelia LSF cluster
* See [Janelia detailed instructions](http://wiki.int.janelia.org/wiki/display/ScientificComputing/LSF+testing+quickstart)
* To start MATLAB with `n` nodes, run `bsub -XF -n X matlab -desktop`
* You can also add this function to your `~/.bashrc` file:

~~~
function startInteractiveMATLAB(){  
	if [ -z "$1" ]  
		then  
			echo "Usage: startInteractiveMATLAB [nNodes]"  
		exit 1  
		fi  
		echo "starting MATLAB with $1 nodes"  
		bsub -XF -n $1 matlab -desktop  
}  
~~~

## Running plates (run on Janelia LSF cluster)

1. Download the week's imaging folder (e.g. `20170711_GCaMP96uf_raw`) to `dm11:\genie\GECIScreenData\GECI_Imaging_Data\`
2. using noMachine (or Putty or ssh) run `.startInteractiveMatlab 1` in terminal on LSF
3. Open run_plates.m. Add the plates from the week's imaging folder to the 'plates' variable, e.g. 'fullfile(GECI_imaging_dir, '20190702_GCaMP96uf_raw/P3a-20190617_GCaMP96uf')'. Edit other parameters as needed (see inline comments in `run_plates.m`). Run.
4. Monitor job status on http://lsf1.int.janelia.org/cluster_status/

## Compile data (run on PC)

1. Open `compile_results_main.m`
2. Edit line: `compile_results(fullfile(GECI_imaging_dir, '20170711_GCaMP96uf_raw'),'GCaMP96uf','0')` with the imaging folder
3. Rename `20170711_GCaMP96uf_raw` to `20170711_GCaMP96uf_analyzed` (not necessary but good to keep track of which folders were analyzed)

## Curate data (run on PC)

1. Open NAA_Curation/NAA_Curation.m and run. It will throw a warning which is OK. Go to the dates/plates you care about and follow the GUI to curate out bad wells
2. When done, click 'Create the data_all file' on top left menu bar. Pick 'GCaMP6uf', check 'Create pile_all_upto', and click OK. This may take several hours.
3. Compiled data is saved in dm11:\genie\GECIScreenData\Analysis.


## NAA_Curation shortcuts

### Plate view  
* L,R,U,D keys: navigate between wells  
* SPACE: go to well  
* BACKSPACE: quick remove well and select reason  

### Well view  
* SPACE: go back  
* BACKSPACE: remove well and select reason  


## Notes

 - Run plates on LSF, compile data and curate on PC
 - Not recently tested with any variants other than GCaMP96uf
 - Also see instructions in run_plates.m
 - if using custom number of AP stimulations (e.g. 1,2,3,5,10,40)
    - rename plate folder to mngGECO
    - in NAA_process_dir_ver4.m set `nominal_pulse = [1,2,3,5,10,40]`
    - in run_plates set `WSoptions.nRecsPerWell = 6`
    - in NAA_pile_df_f.m: set `nAP = [1, 2, 3, 5, 10, 40]`
    - modify `entry={plate,well,construct,` line in NAA_pile_df_f.m to have right number of fields
    - NAA_curation modify `Protocol('mngGECO', ...` line to include correct number of APs
    