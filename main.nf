#!/usr/bin/env nextflow

outdir = params.outdir

def helpMessage() {
    log.info"""
    ==================================================================
    ${workflow.manifest.name}  ~  version ${workflow.manifest.version}
    ==================================================================

    Git info: $workflow.repository - $workflow.revision [$workflow.commitId]

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run Coulab/GENOR --ids ids_file.txt --db db.fasta --libs libs.txt

    Options:
      --ids                         file containing the ids of the proteins, one per line
      --db                          path to queries fasta file
      --libs                        file containing the name of each species db and its path, comma separated, one per line

    Other options:
      --outdir                      The output directory where the results will be saved (default: $outdir)
      -w/--work-dir                 The temporary directory where intermediate data will be saved
      -profile                      Configuration profile to use. [standard, other_profiles] (default 'standard')
    """.stripIndent()
}


id = Channel.fromPath(params.ids).
  splitText(){it.trim()}.
  take( params.sample ). // for testing pourposes
  ifEmpty { error "No ids at  ${params.ids}" }

libs = Channel.fromPath(params.libs).
  splitCsv().
  //collate( 2 ).
  ifEmpty { error "No libs at ${params.libs}" }

//id_libs=id.combine(libs).flatten().collate(3)
db = file(params.db)

process get_queries {
  tag "getting sequence for query $id"
  //echo true
  publishDir "$params.outdir/$id/" , mode:'copy'
  //errorStrategy 'ignore'

  input:
    val id

  output:
    tuple val(id), path('*.fasta') optional true into seqsOut

  script:
  """
  echo $id >> ${id}_ids.txt
    seqtk subseq $db ${id}_ids.txt > ${id}.fasta
  """
}

process jackhammer {

  tag "perform jackhammers for $id at $lib"
  //echo true
  publishDir "$params.outdir/$id/$lib/",pattern:'*.txt',mode:'copy'
  label 'hmmer'


  input:
    tuple val(id), path('sequence.fasta'),val(lib),path("lib.fasta") from seqsOut.combine(libs)

  output:
    tuple val(id),val(lib),path ('lib.fasta'),file("*_doms.txt") into jackhmmerTables
    path "*_table.txt"
    path "*_out.txt"
  script:
  """
   jackhmmer  --seed 1 --cpu $task.cpus -o $id'_'$lib'_out.txt' --tblout $id'_'$lib'_table.txt' --domtblout $id'_'$lib'_doms.txt' sequence.fasta lib.fasta
  """
}

process get_hits {
  tag "get hits from first jackhammer  for $id at $lib"
  //echo true
  publishDir "$params.outdir/$id/$lib/",pattern:'*.txt',mode:'copy'
  //errorStrategy 'ignore'

  input:
    tuple val(id),val(lib),path ('lib.fasta'),path("doms.txt") from jackhmmerTables
  output:
    tuple val(id),val(lib),path ('lib.fasta'),path("*_hits.fasta") optional true into fastas
    path("*_ids.txt")
  script:
  """
    grep -v "#" doms.txt  | cut -f1 -d" "| sort | uniq | grep . | cat > ${lib}_ids.txt
    if test -s ${lib}_ids.txt; then
      seqtk subseq lib.fasta ${lib}_ids.txt > ${lib}_hits.fasta;
    fi
  """
}



process reciprocal_jackhammers {
    label 'hmmer'
    tag "run reciprocal jackhammers for $id at $lib "
    //echo true
    publishDir "$params.outdir/$id/$lib/hits/",pattern:"*_doms.txt",mode:'copy'
    //validExitStatus 0,1

    input:
      tuple val(id),val(lib),path ('lib.fasta'),path("hits.fasta") from fastas
    output:
      tuple val(id),val(lib),path ('lib.fasta'),path("hits_doms.txt") into reciprocal_jackhammers

  script:
  """
    jackhmmer  --seed 1 --cpu $task.cpus -o hits_out.txt --domtblout hits_doms.txt hits.fasta $db
  """
}

process find_reciprocal_hits{
  tag "find reciprocal hits for $id at $lib"
  //echo true
  publishDir "$params.outdir/$id/$lib/hits/",mode:'copy'
  errorStrategy 'ignore'



  input:
    tuple val(id),val(lib),val(lib_fasta),path("hits_doms.txt") from reciprocal_jackhammers
  output:
    path("reciprocal_hits.txt") into reciprocal_hits

  script:
  """
    grep $id hits_doms.txt | tr -s " " "\t" | cut -f 4 | sort | uniq | grep . | perl -ne 'chomp;print "\$_,${id},${lib},${lib_fasta}\n"' > reciprocal_hits.txt
  """
}

process get_reciprocal_seqs {
  tag "get sequences of reciprocal hits $hit for $id at $lib"
  //echo true
  //publishDir "$params.outdir/$id/$lib/hits/"


  input:
    tuple val(hit),val(id),val(lib),path('lib.fasta') from reciprocal_hits.splitCsv()

  output:
    tuple val(hit),val(id),val(lib),path("*_seq.fasta") into reciprocal_hits_seqs

  script:
  """
    echo $hit >> ${hit}_ids.txt
    seqtk subseq lib.fasta ${hit}_ids.txt > ${hit}_seq.fasta
  """
}


process alingments {
  tag "run alignments for $id with $hit at $lib"
  //echo true
  publishDir "$params.outdir/$id/$lib/hits/$hit",mode:'copy'
  //errorStrategy 'finish'
  label 'mafft'

  input:
    tuple val(hit),val(id),val(lib),path (hit_fasta) from reciprocal_hits_seqs

  output:
    tuple val(hit),val(id),val(lib),path("*.aln") into alignments

  script:

  """
    cat $launchDir/$params.outdir/$id/${id}.fasta  $hit_fasta  > aln.fasta ;
    mafft --anysymbol --thread $task.cpus --clustalout --reorder --maxiterate 1000 --retree 1 --globalpair aln.fasta > ${hit}.aln
    rm aln.fasta;
  """
}



process score_alignments {

  tag "score alignments for $id and $hit from $lib"
  publishDir "$params.outdir/$id/$lib/hits/$hit",mode:'copy'


  input:
    tuple val(hit),val (id),val(lib),path(aln_file) from alignments
  output:
    tuple val(id), path( "*_score.txt") into scores
  script:
  """
    #!/usr/bin/env perl

    open FILE,"$aln_file";
    \$my_id=substr("$id",0,15);
    \$my_hit=substr("$hit",0,15);
    \$query_length=`grep \$my_id  $aln_file | tr  -s " " "\\t"  | cut -f2  | tr -d "-" | tr -d "\\n" | wc -c`;
    \$hit_length=  `grep \$my_hit  $aln_file | tr  -s " " "\\t"  | cut -f2  | tr -d "-" | tr -d "\\n" | wc -c`;
    chomp(\$query_length);
    chomp(\$hit_length);
    open OUT,">${hit}_score.txt";
    while(<FILE>){
      next unless /\$my_hit/;
      \$_=<FILE>;
      \$asterisk+=  tr/\\*//;
      \$colon+=  tr/://;
      \$dot+=  tr/\\.//;

    }
    \$score=(\$asterisk*100+\$colon*70+\$dot*30)/\$query_length;
    print OUT "$lib\\t$hit\\t\$asterisk\\t\$colon\\t\$dot\\t\$query_length\\t\$hit_length\\t\$score\\n";
  """
}


process collect_scores {
  tag "collect scores in single file for query $id"
  publishDir "$params.outdir/$id/", mode: 'copy'

  input:
     tuple val(id),path(score_file) from scores.groupTuple()
  output:
     path "${id}_scores.txt"
  script:
  """
   cp  $projectDir/assets/scores_template.txt ${id}_scores.txt
   cat $score_file >> ${id}_scores.txt
  """
}


process collect_scores_one_file {
  tag "collect scores in single file for all queries $id"
  publishDir "$params.outdir/"

   script:
   """
     echo -e "filename\tlib\tid\tasterisks\tcolons\tdots\tquery lenght\thit lenght\tscore" > $params.outdir/All_scores_table.txt
     find $params.outdir -maxdepth 1 -type d -exec bash -c "for d; do for f in \"\$d\"/*.txt; do sed '1d;s/^/\$(basename \$f _scores.txt)\t/' \"\$f\" >> $params.outdir/All_scores_table.txt; done; done" bash {} \;
   """
 }


// Show help message if --help specified
if (params.help){
  helpMessage()
  exit 0
}
