#!/bin/bash
fd_index="./fixel_mask/index.mif"       
tractogram="./tracks_2_million_sift.tck"         
output_dir="./matrix"    
mkdir -p "$output_dir"
echo "Generating fixel-fixel connectivity matrix..."
fixelconnectivity "$fd_index" "$tractogram" "$output_dir"
echo "Connectivity matrix saved to: $output_dir"

matrix_dir="./matrix"
mask="./template_mask.mif"
mkdir -p fd_smooth fc_smooth fdc_smooth
echo "Smoothing FD..."
index=1
for fd_file in ./fd*/fd.mif; do
  out_file="fd_smooth/fd${index}.mif"
  echo "$fd_file → $out_file"
  fixelfilter "$fd_file" smooth "$out_file" -mask "$mask" -matrix "$matrix_dir"
  ((index++))
done
echo "Smoothing FC..."
index=1
for fc_file in ./fc*/IN.mif; do
  out_file="fc_smooth/fc${index}.mif"
  echo "$fc_file → $out_file"
  fixelfilter "$fc_file" smooth "$out_file" -mask "$mask" -matrix "$matrix_dir"
  ((index++))
done
echo "Smoothing FDC..."
index=1
for fdc_file in ./fdc*/fdc.mif; do
  out_file="fdc_smooth/fdc${index}.mif"
  echo "$fdc_file → $out_file"
  fixelfilter "$fdc_file" smooth "$out_file" -mask "$mask" -matrix "$matrix_dir"
  ((index++))
done
echo "Smoothing completed for all metrics."