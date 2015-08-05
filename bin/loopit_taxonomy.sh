#!/bin/bash

for dir
do
    echo $dir
    cd $dir
    rslt=$(bsub -J $dir /home/sgivan/projects/taxonomy_summary/bin/cmd_taxonomy.sh)
    echo $rslt
    cd ..
done


