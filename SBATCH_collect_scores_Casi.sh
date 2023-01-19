#!/bin/bash
#SBATCH -p day
#SBATCH -N 1
#SBATCH -n 10
#SBATCH -J GENOR
#SBATCH --output=GENOR_%j_log.log
#SBATCH --error=GENOR_%j_error.log
#SBATCH --mem=90000
#Place script at GENOR directory

echo -e "query_ID\tlib\tid\tasterisks\tcolons\tdots\tquery lenght\thit lenght\tscore" > /home/ppat/GENOR/All_lncORF_results_Casi_Dsim_transcriptome_combined_scores.txt
find /home/ppat/GENOR/All_lncORF_Dsim_Casi_transcriptome_results_sbatch -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1d;s/^/$(basename $f _scores.txt)\t/" "$f" >> /home/ppat/GENOR/All_lncORF_results_Casi_Dsim_transcriptome_combined_scores.txt; done; done' bash {} \;
