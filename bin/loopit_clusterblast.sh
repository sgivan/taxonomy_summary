#!/bin/bash

for dir
do
    echo $dir
    cd $dir
    stdout=$(splitter -sequence contig.nfa -outseq Csplit.fasta -size 250)
    echo $stdout
    mkdir -p clusterblast_v_ncbi
    cd clusterblast_v_ncbi
    ln -fs ../Csplit.fasta ./seqs
    stdout=$(clusterblast -f seqs -d nt -b blastn -B -a '-num_alignments 20 -num_descriptions 20' -p 2 -W)
    echo $stdout
    cd ..
done


