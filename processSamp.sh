#!/bin/bash

SGE=/home/socci/Work/SGE

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12

LIB=$1
SAMPLE=$2

ODIR=out/${LIB}

mkdir -p ${ODIR}

for R1 in $(ls $DROOT/Sample_$LIB/*R1*gz); do
	R2=${R1/_R1_/_R2_}
	B1=$(basename $R1 | sed 's/.gz//')
	B2=$(basename $R2 | sed 's/.gz//')
	echo $B2, $B2
	qsub -N ZCAT_${LIB} -pe alloc 2 $SGE/qCMD \
	  zcat $R1 \>${ODIR}/$B1
	qsub -N ZCAT_${LIB} -pe alloc 2 $SGE/qCMD \
	  zcat $R2 \>${ODIR}/$B2
    $SGE/qSYNC ZCAT_${LIB}	
	#zcat $R1 | head -40000 >${ODIR}/$B1
	#zcat $R2 | head -40000 >${ODIR}/$B2
	TAG=${B1/_R1_/__}
	TAG=${TAG%%.*}
	qsub -N DOMAP_${LIB} -pe alloc 12 $SGE/qCMD ./doMapping.sh \
	    ${ODIR}/$B1 ${ODIR}/$B2 $SAMPLE $LIB $TAG $TAG
done
$SGE/qSYNC DOMAP_${LIB}

INPUTS=$(ls ${ODIR}/*.bam | awk '{print "I="$1}')
qsub -pe alloc 12 -N MERGE_${LIB} $SGE/qCMD \
    picard MergeSamFiles SO=coordinate CREATE_INDEX=true \
    O=out/${LIB}___${SAMPLE}___RG,Merge.bam $INPUTS
$SGE/qSYNC MERGE_${LIB}

qsub -pe alloc 12 -N MD_${LIB} $SGE/qCMD \
    picard MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
	I=out/${LIB}___${SAMPLE}___RG,Merge.bam \
	O=out/${LIB}___${SAMPLE}___RG,Merge,MD.bam \
	M=out/${LIB}___${SAMPLE}___RG,Merge,MD.txt

