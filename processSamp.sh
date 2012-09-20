#!/bin/bash

SGE=/home/socci/Work/SGE

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12

LIB=$1
SAMPLE=$2

ODIR=out/${LIB}

mkdir -p ${ODIR}

for R1 in $(ls $DROOT/Sample_$LIB/*R1*gz | head -10); do
	R2=${R1/_R1_/_R2_}
	B1=$(basename $R1 | sed 's/.gz//')
	B2=$(basename $R2 | sed 's/.gz//')
	echo $B2, $B2
	zcat $R1 | head -4000 >${ODIR}/$B1
	zcat $R2 | head -4000 >${ODIR}/$B2
	TAG=${B1/_R1_/__}
	TAG=${TAG%%.*}
	qsub -N DOMAP_${LIB} -pe alloc 6 $SGE/qCMD ./doMapping.sh \
	    ${ODIR}/$B1 ${ODIR}/$B2 $SAMPLE $LIB $TAG $TAG
done
$SGE/qSYNC DOMAP_${LIB}

INPUTS=$(ls ${ODIR}/${LIB}/*bam | awk '{print "I="$1}')
qsub -pe alloc 12 -N MERGE_${LIB} $SGE/qCMD \
    picard MergeSamFiles SO=coordinate CREATE_INDEX=true \
    O=${LIB}___${SAMPLE}___RG,Merge.bam $INPUTS
$SGE/qSYNC MERGE_${LIB}

qsub -pe alloc 12 -N MD_${LIB} $SGE/qCMD \
    picard MarkDuplicates CREATE_INDEX=true \
	I=${LIB}___${SAMPLE}___RG,Merge.bam \
	O=${LIB}___${SAMPLE}___RG,Merge,MD.bam \
	M=${LIB}___${SAMPLE}___RG,Merge,MD.txt

