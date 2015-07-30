#!/bin/sh
bs="bsub -R 'span[hosts=1]' -o %J.o -e %J.e"

stdout=$(splitter -sequence contig.nfa -outseq Csplit.fasta -size 250)
echo $stdout
mkdir -p clusterblast_v_ncbi
cd clusterblast_v_ncbi
ln -fs ../Csplit.fasta ./seqs
stdout=$(clusterblast -f seqs -d nt -b blastn -B -a '-num_alignments 20 -num_descriptions 20' -p 2)
echo $stdout
cd ..
stdout=$(bestblastparse.pl -f clusterblast_v_ncbi -b blastn -n 1)
echo $stdout
cat bestblast.tab | cut -f 8 | cut -f 1 -d ' ' > idlist.txt
#~/projects/taxonomy_summary/bin/taxonomy_summary.pl --infile idlist.txt --outfile taxonomy.txt
#stdout=$(bsub -R 'span[hosts=1]' -o %J.o -e %J.e -J taxsum '~/projects/taxonomy_summary/bin/taxonomy_summary.pl --infile idlist.txt --order --taxmap > taxonomy_order.txt')
stdout=$(~/projects/taxonomy_summary/bin/taxonomy_summary.pl --infile idlist.txt --order --taxmap > taxonomy_order.txt)
echo $stdout
#rm -r Csplit.fasta bestblast.tab clusterblast_v_ncbi idlist.txt 
