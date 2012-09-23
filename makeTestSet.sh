#!/bin/bash

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12

LIB=$1
MERGE1=${LIB}___MERGE___R1.fastq
MERGE2=${LIB}___MERGE___R2.fastq

rm -f $MERGE2 $MERGE21

for R1 in $(ls $DROOT/Sample_$LIB/*R1*gz); do
	R2=${R1/_R1_/_R2_}
	echo $R1
	zcat $R1 | head -40000 >>$MERGE1
	zcat $R2 | head -40000 >>$MERGE2
done
