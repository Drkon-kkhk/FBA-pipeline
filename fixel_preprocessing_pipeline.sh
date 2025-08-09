#!/bin/bash
# ======== Configuration ========
num_subjects=YOUR_SAMPLE_NUMBER # Replace with your actual subject count
# ==============================
# ======== Replace the path below with the acyual path to your raw MRI data ========
cd /mnt/c/MRI || { echo "Directory does not exist"; exit 1; }
# =================================================================================
output_folder="./dwi"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_folder="./sub${i}/dMRI" # Folder containing original dwi.nii
    output_file="$output_folder/dwi${i}.mif"
    if [[ -f "$input_folder/dwi.nii" && -f "$input_folder/dwi_bvec.bvec" && -f "$input_folder/dwi_bval.bval" ]]; then
        echo "Processing: $input_folder"
        if mrconvert "$input_folder/dwi.nii" "$output_file" -fslgrad "$input_folder/dwi_bvec.bvec" "$input_folder/dwi_bval.bval"; then
            echo "Saved: $output_file"
        else
            echo "Error mrconvert $input_folder"
        fi
    else
        echo "Missing files in $input_folder:"
        [[ ! -f "$input_folder/dwi.nii" ]] && echo " - dwi.nii missing"
        [[ ! -f "$input_folder/dwi_bvec.bvec" ]] && echo " - dwi_bvec.bvec missing"
        [[ ! -f "$input_folder/dwi_bval.bval" ]] && echo " - dwi_bval.bval missing"
        echo "Skipping..."
    fi
done

output_folder="./dwi_denoised"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file="./dwi/dwi${i}.mif"
    output_file="$output_folder/dwi_denoised${i}.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if dwidenoise "$input_file" "$output_file"; then
            echo "Saved: $output_file"
        else
            echo "Error dwidenoise $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder="./dwi_den_unr"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file="./dwi_denoised/dwi_denoised${i}.mif"
    output_file="$output_folder/dwi_den_unr${i}.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if mrdegibbs "$input_file" "$output_file" -axes 0,1; then
            echo "Saved: $output_file"
        else
            echo "Error mrdegibbs $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder="./dwi_den_unr_preproc"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file="./dwi_den_unr/dwi_den_unr${i}.mif"
    output_file="$output_folder/dwi_den_unr_preproc${i}.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if dwifslpreproc "$input_file" "$output_file" -pe_dir AP -rpe_none; then
            echo "Saved: $output_file"
        else
            echo "Error dwifslpreproc $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder="./dwi_den_unr_preproc_unbiased"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file="./dwi_den_unr_preproc/dwi_den_unr_preproc${i}.mif"
    output_file="$output_folder/dwi_den_unr_preproc_unbiased${i}.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if dwibiascorrect ants "$input_file" "$output_file"; then
            echo "Saved: $output_file"
        else
            echo "Error dwibiascorrect $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder1="./wm"
output_folder2="./gm"
output_folder3="./csf"
mkdir -p "$output_folder1"
mkdir -p "$output_folder2"
mkdir -p "$output_folder3"
for i in {1..$num_subjects}; do
    input_file="./dwi/dwi${i}.mif"
    output_file1="$output_folder1/response_wm${i}.txt"
    output_file2="$output_folder2/response_gm${i}.txt"
    output_file3="$output_folder3/response_csf${i}.txt"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if dwi2response dhollander "$input_file" "$output_file1" "$output_file2" "$output_file3"; then
            echo "Saved WM response to: $output_file1"
            echo "Saved GM response to: $output_file2"
            echo "Saved CSF response to: $output_file3"
        else
            echo "Error: dwi2response failed for $input_file"
            exit 1
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done
echo "All files processed successfully."

output_file="./group_average_response_wm.txt"
input_files=(./wm/*)
if [ ${#input_files[@]} -eq 0 ]; then
    echo "No input files found in ./wm/"
    exit 1
fi
echo "Input files:"
for file in "${input_files[@]}"; do
    echo "  $file"
done
if responsemean "${input_files[@]}" "$output_file"; then
    echo "Saved average response to: $output_file"
else
    echo "Failed to generate group average response."
fi

output_file="./group_average_response_gm.txt"
input_files="./gm/*"
for input_file in $input_files; do
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if responsemean "$input_file" "$output_file"; then
            echo "Saved: $output_file"
        else
            echo "Error processing file: $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_file="./group_average_response_csf.txt"
input_files="./csf/*"
for input_file in $input_files; do
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if responsemean "$input_file" "$output_file"; then
            echo "Saved: $output_file"
        else
            echo "Error processing file: $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder="./dwi_denoised_unringed_preproc_unbiased_upsampled"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file="./dwi_den_unr_preproc_unbiased/dwi_den_unr_preproc_unbiased${i}.mif"
    output_file="$output_folder/dwi_denoised_unringed_preproc_unbiased_upsampled${i}.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if mrgrid "$input_file" regrid -vox 1.25 "$output_file"; then
            echo "Saved: $output_file"
        else
            echo "Error mrgrid $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

output_folder1="./wmfod"
output_folder2="./gm"
output_folder3="./csf"
mkdir -p "$output_folder1"
mkdir -p "$output_folder2"
mkdir -p "$output_folder3"
for i in {1..$num_subjects}; do
    input_file1="./dwi_denoised_unringed_preproc_unbiased_upsampled/dwi_denoised_unringed_preproc_unbiased_upsampled${i}.mif"
    # ======== IMPORTANT =======
    # brain_mask${i}.mif must match the dimensions of the preprocessed DWI image
    # If not, please resample the mask accordingly using MRtrix tools
    input_file2="./brain_mask/brain_mask${i}.mif"
    # =========================
    input_file3="./group_average_response_wm.txt"
    input_file4="./group_average_response_gm.txt"
    input_file5="./group_average_response_csf.txt"
    output_file1="$output_folder1/wmfod${i}.mif"
    output_file2="$output_folder2/gm${i}.mif"
    output_file3="$output_folder3/csf${i}.mif"
    if [[ -f "$input_file1" && -f "$input_file2" && -f "$input_file3" && -f "$input_file4" && -f "$input_file5" ]]; then
        echo "Processing: $input_file1"
        if dwi2fod msmt_csd "$input_file1" "$input_file3" "$output_file1" "$input_file4" "$output_file2" "$input_file5" "$output_file3" -mask "$input_file2"; then
            echo "Saved WM FOD to: $output_file1"
            echo "Saved GM FOD to: $output_file2"
            echo "Saved CSF FOD to: $output_file3"
        else
            echo "Error: dwi2fod failed for $input_file1"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
        [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
        [[ ! -f "$input_file3" ]] && echo "  Missing: $input_file3"
        [[ ! -f "$input_file4" ]] && echo "  Missing: $input_file4"
        [[ ! -f "$input_file5" ]] && echo "  Missing: $input_file5"
    fi
done
echo "All files processed successfully."

output_folder1="./wmfod_norm"
output_folder2="./gm_norm"
output_folder3="./csf_norm"
mkdir -p "$output_folder1"
mkdir -p "$output_folder2"
mkdir -p "$output_folder3"
for i in {1..$num_subjects}; do
    input_file1="./wmfod/wmfod${i}.mif"
    input_file2="./gm/gm${i}.mif"
    input_file3="./csf/csf${i}.mif"
    input_file4="./brain_mask/brain_mask${i}.mif"
    output_file1="$output_folder1/wmfod_norm${i}.mif"
    output_file2="$output_folder2/gm_norm${i}.mif"
    output_file3="$output_folder3/csf_norm${i}.mif"
    if [[ -f "$input_file1" && -f "$input_file2" && -f "$input_file3" && -f "$input_file4" ]]; then
        echo "Processing: $input_file1"
        if mtnormalise  "$input_file1" "$output_file1" "$input_file2" "$output_file2" "$input_file3" "$output_file3" -mask "$input_file4"; then
            echo "Saved WM FOD to: $output_file1"
            echo "Saved GM FOD to: $output_file2"
            echo "Saved CSF FOD to: $output_file3"
        else
            echo "Error: mtnormalise failed for $input_file1"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
        [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
        [[ ! -f "$input_file3" ]] && echo "  Missing: $input_file3"
        [[ ! -f "$input_file4" ]] && echo "  Missing: $input_file4"
    fi
done
echo "All files processed successfully."

cd ./brain_mask
a=1
for f in $(ls -v brain_mask*.mif); do
    mv "$f" "$(printf "wmfod%d_mask.mif" $a)"
    a=$((a+1))
done
cd -

output_folder="./dwi_mask_in_template_space"
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file1="./brain_mask/wmfod${i}_mask.mif"
    input_file2="./subject2template_warp/subject2template_warp${i}.mif"
    output_file="$output_folder/dwi_mask_in_template_space${i}.mif"
    if [[ -f "$input_file1" ]] && [[ -f "$input_file2" ]]; then
    echo "Processing: $input_file1"
    if mrtransform "$input_file1" -warp "$input_file2" -interp nearest -datatype bit "$output_file"; then
        echo "Saved to: $output_file"
    else
        echo "Error: mrtransform failed for $input_file1"
        exit 1
    fi
else
    echo "Missing input file(s), skipping iteration $i:"
    [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
    [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
fi
done
echo "All files processed successfully."

output_file="./template_mask.mif"
input_folder="./dwi_mask_in_template_space"
input_files=($input_folder/*.mif)
if [ ${#input_files[@]} -lt 2 ]; then
    echo "[ERROR] Not enough input files to combine. Found ${#input_files[@]} file(s)."
    exit 1
fi
echo "Combining all mask files with min operation..."
if mrmath "${input_files[@]}" min "$output_file" -datatype bit; then
    echo "Successfully created combined mask: $output_file"
else
    echo "Failed to combine masdk files"
    exit 1
fi
echo "All files processed successfully."
# WARNING: The resulting combined mask (using min operation) may be too strict.
# If the final mask does NOT cover the whole brain, please manually select one subject's individual mask that fully covers the whole brain and use it instead.

input_file1="./template_mask.mif"
input_file2="./wmfod_template.mif"
output_folder="./fixel_mask"
output_file="./fd.mif"
mkdir -p "$output_folder"
if [[ -f "$input_file1" && -f "$input_file2" ]]; then
    echo "Running fod2fixel..."
    if fod2fixel -mask "$input_file1" "$input_file2" -afd "$output_file" "$output_folder" -force; then
        echo "fod2fixel succeeded, output saved in $output_folder"
    else
        echo "Error: fod2fixel failed."
    fi
else
    echo "Missing input file(s):"
    [[ ! -f "$input_file1" ]] && echo "  - $input_file1 not found"
    [[ ! -f "$input_file2" ]] && echo "  - $input_file2 not found"
fi

output_folder=./fod_in_template_space_NOT_REORIENTED
mkdir -p "$output_folder"
for i in {1..$num_subjects}; do
    input_file1=./wmfod/wmfod${i}.mif                  
    input_file2=./subject2template_warp/subject2template_warp${i}.mif
    output_file=${output_folder}/fod_in_template_space_NOT_REORIENTED${i}.mif
    if [[ -f "$input_file1" ]] && [[ -f "$input_file2" ]]; then
        echo "Processing: $input_file1"
        if mrtransform "$input_file1" -warp "$input_file2" -reorient_fod yes "$output_file"; then
            echo "Saved to: $output_file"
        else
            echo "Error: mrtransform failed for $input_file1"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
        [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
    fi
done
echo "ALL FODs warped to template space successfully."

for i in {1..$num_subjects}; do
    input_file1=./template_mask.mif
    input_file2=./fod_in_template_space_NOT_REORIENTED/fod_in_template_space_NOT_REORIENTED${i}.mif
    output_folder=./fixel_in_template_space_NOT_REORIENTED${i}
    output_file=./fd.mif
    mkdir -p "$output_folder"
    if [[ -f "$input_file1" ]] && [[ -f "$input_file2" ]]; then
        echo "Processing: $input_file2"
        if fod2fixel -mask "$input_file1" "$input_file2" "$output_folder" -afd "$output_file" -force; then
            echo "Saved to: $output_file"
        else
            echo "Error: fod2fixel failed for $input_file2"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
        [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
    fi
done
echo "ALL files processed successfully."

for i in {1..$num_subjects}; do
    input_folder="./fixel_in_template_space_NOT_REORIENTED${i}"
    input_file="./subject2template_warp/subject2template_warp${i}.mif"
    output_folder="fixel_in_template_space${i}"
    if [[ -d "$input_folder" && -f "$input_file" ]]; then
        echo "Processing: $input_folder"
        if fixelreorient "$input_folder" "$input_file" "$output_folder"; then
            echo "Saved to: $output_folder"
        else
            echo "Error: fixelreorient failed for $input_folder"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -d "$input_folder" ]] && echo "  Missing directory: $input_folder"
        [[ ! -f "$input_file" ]] && echo "  Missing file: $input_file"
    fi
done
echo "All files processed successfully."

for i in {1..$num_subjects}; do
    input_file="./fixel_in_template_space${i}/fd.mif"
    template_dir="./fixel_mask"
    output_folder="./fd${i}"
    output_file="fd.mif" 
    if [[ -f "$input_file" ]]; then 
        echo "Processing: $input_file"
        mkdir -p "$output_folder"
        if fixelcorrespondence "$input_file" "$template_dir" "$output_folder" "$output_file"; then
            echo "Saved: $output_folder/$output_file"
        else
            echo "Error running fixelcorrespondence for $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

for i in {1..$num_subjects}; do
    input_file="./subject2template_warp/subject2template_warp${i}.mif"
    output_folder="./fc${i}"
    output_file="./IN.mif"
    if [[ -f "$input_file" ]]; then
        echo "Processing: $input_file"
        if warp2metric "$input_file" -fc fixel_mask "$output_folder" "$output_file" -force; then
            echo "Saved: $output_file"
        else
            echo "Error warp2metric $input_file"
        fi
    else
        echo "Missing file: $input_file, skipping..."
    fi
done

for i in {1..$num_subjects}; do
    input_file1="./fd${i}/fd.mif"
    input_file2="./fc${i}/IN.mif"
    output_folder="./fdc${i}"
    output_file="${output_folder}/fdc.mif"
    if [[ -f "$input_file1" && -f "$input_file2" ]]; then
        mkdir -p "$output_folder" 
        echo "Processing: $input_file1 * $input_file2"
        if mrcalc "$input_file1" "$input_file2" -mult "$output_file" -force; then
            echo "Saved to: $output_file"
        else
            echo "Error: mrcalc failed for $i"
            exit 1
        fi
    else
        echo "Missing input file(s), skipping iteration $i:"
        [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
        [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
    fi
done

for i in {1..$num_subjects}; do
    if cp "./fc${i}/directions.mif" "./fdc${i}/" 2>/dev/null; then
        echo "Copied directions.mif to fdc${i}"
    else
        echo "Missing directions.mif in fc${i}"
    fi
    if cp "./fc${i}/index.mif" "./fdc${i}/" 2>/dev/null; then
        echo "Copied index.mif to fdc${i}"
    else
        echo "Missing index.mif in fc${i}"
    fi
done
echo "Copy operation completed"

input_file1="./wmfod_template.mif"
input_file2="./template_mask.mif"
input_file3="./template_mask.mif"
output_file="./tracks_20_million.tck"
if [[ -f "$input_file1" ]] && [[ -f "$input_file2" ]] && [[ -f "$input_file3" ]]; then
    echo "Processing: $input_file1"
    if tckgen -angle 22.5 -maxlen 200 -minlen 1 -power 1.0 "$input_file1" -seed_image "$input_file2" -mask "$input_file3"  -select 20000000 -cutoff 0.01 "$output_file"; then
        echo "Saved to: $output_file"
    else
        echo "Error: tckgen failed for $input_file1"
        exit 1
    fi
else
    echo "Missing input file(s), skipping iteration $i:"
    [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
    [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
    [[ ! -f "$input_file3" ]] && echo "  Missing: $input_file3"
fi

input_file1="./tracks_20_million.tck"
input_file2="./wmfod_template.mif"
output_file="./tracks_2_million_sift.tck"
if [[ -f "$input_file1" ]] && [[ -f "$input_file2" ]]; then
    echo "Processing: $input_file1"
    if tcksift "$input_file1" "$input_file2" "$output_file" -term_number 2000000; then
        echo "Saved to: $output_file"
    else
        echo "Error: tcksift failed for $input_file1"
        exit 1
    fi
else
    echo "Missing input file(s), skipping iteration $i:"
    [[ ! -f "$input_file1" ]] && echo "  Missing: $input_file1"
    [[ ! -f "$input_file2" ]] && echo "  Missing: $input_file2"
fi