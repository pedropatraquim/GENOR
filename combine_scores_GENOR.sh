#Combine GENOR scores for all lncORFs into one file
echo -e "filename\tlib\tid\tasterisks\tcolons\tdots\tquery lenght\thit lenght\tscore" > /home/ppat/GENOR/All_lncORF_results_combined_scores.txt
find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1d;s/^/$(basename $f _scores.txt)\t/" "$f" >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt; done; done' bash {} \;
