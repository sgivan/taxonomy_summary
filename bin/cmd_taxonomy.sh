#!/bin/sh
bs="bsub -R 'span[hosts=1]' -o %J.o -e %J.e"

type=$1
#echo $type

stdout=$(bestblastparse.pl -f clusterblast_v_ncbi -b blastn -n 1)
echo $stdout
cat bestblast.tab | cut -f 8 | cut -f 1 -d ' ' > idlist.txt
if [[ $type == "order" ]] 
then
    stdout=$(~/projects/taxonomy_summary/bin/taxonomy_summary.pl --infile idlist.txt --order --taxmap > taxonomy_order.txt)
else
    stdout=$(~/projects/taxonomy_summary/bin/taxonomy_summary.pl --infile idlist.txt --class --taxmap > taxonomy_class.txt)
fi
echo $stdout
#rm -r Csplit.fasta bestblast.tab clusterblast_v_ncbi idlist.txt 
