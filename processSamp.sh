#!/bin/bash

source bin/paths.sh

SAMPLE=$1
R1=$2
R2=$3
ODIR=out/${SAMPLE}
ODIR1=out

mkdir -p ${ODIR}

echo -n "Uncompressing FASTQ's ..."
zcat $R1 >$ODIR/R1.fastq
zcat $R2 >$ODIR/R2.fastq
echo " DONE"

./doMapping.sh $ODIR/R1.fastq $ODIR/R2.fastq $SAMPLE $SAMPLE $SAMPLE $SAMPLE

$PICARD MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
	I=$ODIR/${SAMPLE}__RG.bam \
	O=$ODIR/${SAMPLE}__RG,MD.bam \
	M=$ODIR/${SAMPLE}__RG,MD.txt 

samtools view -b -q 30 \
  $ODIR/${SAMPLE}__RG,MD.bam \
  > $ODIR/${SAMPLE}__RG,MD,QFlt30.bam

$PICARD BuildBamIndex I=$ODIR/${SAMPLE}__RG,MD,QFlt30.bam
