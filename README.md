# fixel_preprocessing_pipeline.sh
## Purpose
This repository provides a full automated shell pipeline for preprocessing diffusion MRI (DWI) data and performing fixel-based analysis using MRtrix3. It supports batch processing for multiple subjects, from raw .nii DWI images to fixel-wise metrics (FD, FC, FDC) in template space.
## Requirements
- MRtrix3 (3.3.7)
- FSL (for dwifslpreproc)
- ANTs (for dwibiascorrect ants)
- Bash environment (Linux/macOS or WSL on Windows)
## Key Steps
1.	**Conversion of raw DWI data to MRtrix .mif format.**
2.	**Denoising and Gibbs ringing removal for noise/artifact reduction.**
3.	**Eddy current & motion correction using FSL.**
4.	**Bias field correction with ANTs.**
5.	**Upsampling of DWI data for higher spatial resolution.**
6.	**Tissue response function estimation (WM/GM/CSF) using Dhollander algorithm.**
7.	**Group average response computation across subjects.**
8.	**Multi-shell multi-tissue FOD estimation (msmt-CSD).**
9.	**FOD intensity normalization using mtnormalise.**
10.	**Template space warping and mask generation.**
11.	**Fixel extraction and computation of:**
	- FD (Fiber Density)
	- FC (Fiber Cross-section)
	- FDC (FD × FC)
12.	**Reorientation and correspondence mapping to template.**
13.	**Whole-brain tractography and streamline filtering via SIFT.**
## Inputs
| File / Folder | Description |
|------|-------------|
| `sub*/dMRI/` | A foldr containing raw diffusion weighted images (dwi.nii) and corresponding bvec, bval files (per subject) |
| `brain_mask*.mif`  | Brain mask (per subject) |
## Outputs
| File / Folder | Description |
|------|-------------|
| `wmfod_norm*.mif`, `gm_norm*.mif`, `csf_norm*.mif` | Normalized WM FOD, GM and CSF maps (per subject) |
| `wmfod_template.mif` | FOD population template |
| `template_mask.mif` | Brain mask in template space |
| `fixel_mask/` | Fixel mask folder (includes `index.mif`, `directions.mif`) |
| `fd*/fd.mif` | Fiber Density (FD) maps for all subjects |
| `fc*/IN.mif` | Fiber Cross-section (log FC) maps for all subjects |
| `fdc*/fdc.mif` | Combined FD and FC maps for all subjects |
| `fd*/index.mif`, `fd*/directions.mif` | Fixel indices and directions used in FD fixel analysis |
| `fc*/index.mif`, `fc*/directions.mif` | Fixel indices and directions used in FC fixel analysis |
| `fdc*/index.mif`, `fdc*/directions.mif` | Fixel indices and directions used in FDC fixel analysis |
| `tracks_2_million_sift.tck` | Whole-brain tractogram (2 million streamlines) |
## Usage
1.	Set the subject count at the top of the script:
num_subjects=YOUR_SAMPLE_NUMBER
2.	Run the pipeline:
sed -i 's/\r$//' fixel_preprocessing_pipeline.sh
chmod +x fixel_preprocessing_pipeline.sh
bash fixel_preprocessing_pipeline.sh
## Notes
- Make sure all brain masks and warps are in the correct space and dimensions.
- The final group mask is created via intersection across subjects — adjust manually if too strict.
- You can integrate further statistical analysis using fixelcfestats based on these outputs.

# demean_design_matrix.sh
## Purpose
This script normalizes selected columns of a design matrix to the range [0, 1], specifically for use in fixelcfestats during fixel-based analysis in MRtrix3.
Normalization ensures that continuous covariates (e.g., age, weight) are on comparable scales and improves model stability.
## Inputs
| File | Description |
|------|-------------|
| `design_matrix.txt` | Plain text file containing numerical design matrix data |
## Outputs
| File | Description |
|------|-------------|
| `design_matrix_demean.txt` | New design matrix with specified columns min-max normalized to range [0,1] | 
## Usage
1.	Open the script and edit the following section if needed:
min_col3=$(awk 'NR==1{min=$3; max=$3} NR>1{if($3<min)min=$3; if($3>max)max=$3} END{print min}' "$input_file")
max_col3=$(awk 'NR==1{min=$3; max=$3} NR>1{if($3<min)min=$3; if($3>max)max=$3} END{print max}' "$input_file")
min_col4=$(awk 'NR==1{min=$4; max=$4} NR>1{if($4<min)min=$4; if($4>max)max=$4} END{print min}' "$input_file")
max_col4=$(awk 'NR==1{min=$4; max=$4} NR>1{if($4<min)min=$4; if($4>max)max=$4} END{print max}' "$input_file")
and:
$3 = ($3 - min3) / (max3 - min3);
$4 = ($4 - min4) / (max4 - min4);
2.	Also update the print statement to match the number of columns in your file:
- Example for 4 columns:
print $1, $2, $3, $4
3.	Run the script:
sed -i 's/\r$//' demean_design_matrix.sh
chmod +x demean_design_matrix.sh
bash demean_design_matrix.sh
## Notes
- Column indices in awk are 1-based (i.e., $1 = first column).
- This script currently handles two columns, but you can expand it as needed.
- Ensure consistent column formatting (e.g., no headers, no missing values).

# smooth_fixel_metrics.sh
## Purpose
This script performs fixel-fixel connectivity generation and spatial smoothing of three fixel-based metrics (FD, FC, FDC) for all subjects. It is used in preprocessing before statistical analysis with fixelcfestats in MRtrix3.
## Requirements
- MRtrix3 (3.3.7)
## Key Steps
1.	**Create fixel-fixel connectivity matrix**
- Uses fixelconnectivity to compute structural relationships between fixels based on streamline density.
2.	**Smooth FD (Fiber Density)**
- Applies fixelfilter smooth with the fixel mask and connectivity matrix.
3.	**Smooth FC (log-Fiber Cross-section)**
- Applies fixelfilter smooth
4.	**Smooth FDC (FD × FC)**
- Applies fixelfilter smooth
## Inputs
| File | Description |
|------|-------------|
| `fixel_mask/index.mif` | Fixel index file from the fixel mask |
| `tracks_2_million_sift.tck` | Whole-brain tractogram generated from tckgen + tcksift |
| `fd*/fd.mif` | FD files (per subject) |
| `fc*/IN.mif` | FC files (per subject) |
| `fdc*/fdc.mif` | FDC files (per subject) |
| `template_mask.mif` | Fixel mask in template space |
## Outputs
| File | Description |
|------|-------------|
| `fd_smooth/fd*.mif` |	Smoothed FD files (per subject) |
| `fc_smooth/fc*.mif` |	Smoothed FC files (per subject) |
| `fdc_smooth/fdc*.mif` | Smoothed FDC files (per subject) |
## Usage
1.	Ensure you have the following prepared:
- Fixel mask: fixel_mask/index.mif
- Tractogram: tracks_2_million_sift.tck
- FD / FC / FDC files in their respective folders
2.	Run the script:
sed -i 's/\r$//' smooth_fixel_metrics.sh
chmod +x smooth_fixel_metrics.sh
bash smooth_fixel_metrics.sh
## Notes
- The fixel-fixel connectivity matrix is generated once, based on fixel geometry and streamline density.
- Smoothing uses MRtrix3’s fixelfilter smooth, guided by the matrix and fixel mask.
- Make sure that all input fixel files (fd, fc, fdc) match the template fixel mask and matrix in orientation and resolution.

# Technical Contributions
- Automated the complete MRtrix FBA preprocessing pipeline
- Implemented batch demean processing for covariate design matrices
- Generated outputs directly compatible with `fixelcfestats`
- Designed modular scripts for reproducibility and scalability
