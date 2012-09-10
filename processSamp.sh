#!/bin/bash

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12
LIB=$1
SAMPLE=$2

mkdir -p out

MERGE1=out/${LIB}___${SAMPLE}__R1.fastq
MERGE2=out/${LIB}___${SAMPLE}__R2.fastq

rm -f $MERGE1 $MERGE2

for R1 in $DROOT/Sample_$LIB/*R1*gz; do
	R2=${R1/_R1_/_R2_}
    zcat $R1 >>$MERGE1
    zcat $R2 >>$MERGE2
    echo $(basename $R1)
done

qsub -N DOMAP -pe alloc 12 /home/socci/Work/SGE/qCMD ./doMapping_Int.sh \
	$MERGE1 $MERGE2 $SAMPLE $LIB ${LIB} ${LIB}  
