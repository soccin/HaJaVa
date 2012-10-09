#!/bin/bash

source bin/paths.sh

SAMPLE=$1
R1=$2
R2=$3
ODIR=out/${SAMPLE}
ODIR1=out

mkdir -p ${ODIR}

./doMapping.sh $R1 $R2 $SAMPLE $SAMPLE $SAMPLE $SAMPLE

$PICARD MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
	I=$ODIR/${SAMPLE}__RG.bam \
	O=$ODIR/${SAMPLE}__RG,MD.bam \
	M=$ODIR/${SAMPLE}__RG,MD.txt

$SAMTOOLS view -b -q 30 \
  $ODIR/${SAMPLE}__RG,MD.bam \
  > $ODIR/${SAMPLE}__RG,MD,QFlt30.bam

$PICARD BuildBamIndex I=$ODIR/${SAMPLE}__RG,MD,QFlt30.bam
