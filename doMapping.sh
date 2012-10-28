#!/bin/bash

#
# This script does all the processing that can be done on a single sample
#
#   Clip
#   BWA (aln, sampe)
#   RG
#   Drop Duplicates
#
# This version expects two input files (FASTQ UNCOMPRESSED)
#    R1.fastq
#    R2.fastq
#
# Output a single BAM file.
#
# ARGS
#   R1.fastq
#   R2.fastq
#   SampleName (for RG)
#   LibName
#   PUnit
#   RG_ID
#
#   We assume the platform is Illumina for RG

source bin/paths.sh
source data/dataPaths.sh
source bin/sge.sh

ADAPTER=AGATCGGAAGAGCACACGTCTGAACTCCAGTCA

FASTQ1=$1
FASTQ2=$2

SAMPLENAME=$3
LIBNAME=$4
PUNIT=$5
RGID=$6

ODIR=out/${LIBNAME}
BASE1=$(basename $FASTQ1)
BASE1=$ODIR/${BASE1%%.*}
BASE2=$(basename $FASTQ2)
BASE2=$ODIR/${BASE2%%.*}
TAG=${PUNIT}

mkdir -p $ODIR

echo $BASE1, $BASE2

OUT1=${BASE1}__clip.fastq
OUT2=${BASE2}__clip.fastq

bin/clipAdapters.sh $FASTQ1 $FASTQ2 $OUT1 $OUT2 $ADAPTER

IN1=$OUT1
IN2=$OUT2
OUT1=${OUT1%%.*}.aln
OUT2=${OUT2%%.*}.aln


qsub -pe alloc 5 -N BWA__$TAG $QCMD \
  $BWA aln -t 12 $GENOME_BWA $IN1 \>$OUT1
qsub -pe alloc 5 -N BWA__$TAG $QCMD \
  $BWA aln -t 12 $GENOME_BWA $IN2 \>$OUT2
$QSYNC BWA__$TAG

OUT12=$ODIR/${PUNIT}.sam

$BWA sampe -f $OUT12 $GENOME_BWA $OUT1 $OUT2 $IN1 $IN2

cat $OUT12 | bin/filterProperPair.py >${OUT12%%.sam}__fPE.sam

$PICARD AddOrReplaceReadGroups \
	I=${OUT12%%.sam}__fPE.sam O=${OUT12%%.sam}__RG.bam CREATE_INDEX=true SO=coordinate \
	ID=$RGID PL=illumina LB=$LIBNAME PU=$PUNIT SM=$SAMPLENAME

#rm $IN1 $IN2 $OUT1 $OUT2 $OUT12 ${OUT12%%.sam}__fPE.sam
