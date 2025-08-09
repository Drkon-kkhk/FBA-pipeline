#!/bin/bash
input_file="design_matrix.txt"
output_file="design_matrix_demean.txt"
# ======== Change to your target column ========
min_col3=$(awk 'NR==1{min=$3; max=$3} NR>1{if($3<min)min=$3; if($3>max)max=$3} END{print min}' "$input_file")
max_col3=$(awk 'NR==1{min=$3; max=$3} NR>1{if($3<min)min=$3; if($3>max)max=$3} END{print max}' "$input_file")
min_col4=$(awk 'NR==1{min=$4; max=$4} NR>1{if($4<min)min=$4; if($4>max)max=$4} END{print min}' "$input_file")
max_col4=$(awk 'NR==1{min=$4; max=$4} NR>1{if($4<min)min=$4; if($4>max)max=$4} END{print max}' "$input_file")
awk -v min3=$min_col3 -v max3=$max_col3 -v min4=$min_col4 -v max4=$max_col4 '{
    $3 = ($3 - min3) / (max3 - min3);
    $4 = ($4 - min4) / (max4 - min4);
    # ======== Adjust the following `print` statement to match the number of columns in your design matrix =========
    print $1, $2, $3, $4
}' "$input_file" > "$output_file"