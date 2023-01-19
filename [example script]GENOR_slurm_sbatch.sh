#!/bin/bash
#SBATCH -p day
#SBATCH -N 1
#SBATCH -n 10
#SBATCH -J GENOR
#SBATCH --output=GENOR_%j_log.log
#SBATCH --error=GENOR_%j_error.log
#SBATCH --mem=90000
#Place script at GENOR

module load Miniconda3/4.4.10
module load HMMER
module load MAFFT
export PATH=$PATH:/home/pedropatraquim/GENOR/seqtk

./nextflow pull pedropatraquim/GENOR
nextflow run -r main pedropatraquim/GENOR --db All_lncORFs.fasta --ids lncORF_ids.txt --libs libs.txt  --profile standard --outdir All_lncORF_results
