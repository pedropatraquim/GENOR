#Combine GENOR scores for all lncORFs into one file
find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -mindepth 1 -type f -iname '*scores.txt' -exec cat {} \; >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt

find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -mindepth 1 -type f -iname '*scores.txt' -exec cat {} \; >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt

find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type f -iname '*scores.txt' -exec sh -c 'for f; do while read line; do echo "$f: $line"; done < "$f"; done' sh {} \; >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt
find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1!s/^/$(basename $f): /" "$f" >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt; done; done' bash {} \;
find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1!s/^/$(basename $f _scores.txt): /" "$f" >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt; done; done' bash {} \;
find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1!d" "$f" >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt; done; done' bash {} \; | awk '!seen[$0]++' | sed -i '1i lib	id	asterisks	colons	dots	query lenght	hit lenght	score' /home/ppat/GENOR/All_lncORF_results_combined_scores.txt

find /home/ppat/GENOR/All_lncORF_results -maxdepth 1 -type d -exec bash -c 'for d; do for f in "$d"/*.txt; do sed "1!s/^/$(basename $f): /" "$f" >> /home/ppat/GENOR/All_lncORF_results_combined_scores.txt; done; done' bash {} \; 
echo -e "lib\tid\tasterisks\tcolons\tdots\tquery lenght\thit lenght\tscore" | cat - /home/ppat/GENOR/All_lncORF_results_combined_scores.txt > temp && mv temp /home/ppat/GENOR/All_lncORF_results_combined_scores.txt
