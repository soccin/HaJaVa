#!/bin/bash

source bin/paths.sh
source data/dataPaths.sh
source bin/sge.sh


ARGS=$1

SAMPLE=$(echo $ARGS | awk -F"@" '{print $1}')
R1=$(echo $ARGS | awk -F"@" '{print $2}')
R2=$(echo $ARGS | awk -F"@" '{print $3}')
ODIR=out/${SAMPLE}
ODIR1=out
TAG=$(basename ${R1} | sed 's/.fast.*//')

mkdir -p ${ODIR}

#qsub -pe alloc 2 -N MAP_${TAG} $QCMD \
    ./doMapping.sh $R1 $R2 $SAMPLE $SAMPLE $TAG $SAMPLE
#QSYNC MAP_${TAG}

#qsub -pe alloc 3 -N MD_${TAG} $QCMD \
    $PICARD MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
	I=$ODIR/${TAG}__RG.bam \
	O=$ODIR/${TAG}__RG,MD.bam \
	M=$ODIR/${TAG}__RG,MD.txt
#QSYNC MD_${TAG}

#qsub -pe alloc 3 -N FLT_${TAG} $QCMD \
    $SAMTOOLS view -b -q 30 \
    $ODIR/${TAG}__RG,MD.bam \
    > $ODIR/${TAG}__RG,MD,QFlt30.bam
#QSYNC FLT_${TAG}

#qsub -pe alloc 3 -N RG_${TAG} $QCMD \
    $PICARD BuildBamIndex I=$ODIR/${TAG}__RG,MD,QFlt30.bam
#QSYNC RG_${TAG}
