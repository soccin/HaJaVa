#!/bin/bash

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12
LIB=$1
SAMPLE=$2

mkdir -p out

for R1 in $DROOT/Sample_$LIB/*R1*gz; do
	R2=${R1/_R1_/_R2_}
	B1=$(basename $R1 | sed 's/.gz//')
	B2=$(basename $R2 | sed 's/.gz//')
	echo $B2, $B2
	zcat $R1 | head -40000 >out/$B1
	zcat $R2 | head -40000 >out/$B2
	TAG=${B1/_R1_/__}
	TAG=${TAG%%.*}
	qsub -N DOMAP -pe alloc 12 /home/socci/Work/SGE/qCMD ./doMapping.sh \
	    out/$B1 out/$B2 $SAMPLE $LIB $TAG $TAG
done

