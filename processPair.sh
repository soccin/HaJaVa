#!/bin/bash

##################################################################################
#
# processPair.sh
#
# Main driver script to process a tumor/normal pair
#
# Usage:
#    ./processPair.sh \
#		SAMPLE_NAME_NORMAL NORMAL_R1_FASTQ.gz NORMAL_R2_FASTQ.gz  \
#		SAMPLE_NAME_TUMOR TUMOR_R1_FASTQ.gz TUMOR_R2_FASTQ.gz
#
# These scripts expect that the sequence files are compressed
#

source bin/sge.sh

NORMAL=$1
NORMAL_R1=$2
NORMAL_R2=$3

TUMOR=$4
TUMOR_R1=$5
TUMOR_R2=$6

echo "##TS:PP1:" `date`
#qsub -pe alloc 6 -N PROCESS_SAMP $QCMD \
  ./processSamp.sh $NORMAL $NORMAL_R1 $NORMAL_R2
echo "##TS:PP2:" `date`
#qsub -pe alloc 6 -N PROCESS_SAMP $QCMD \
  ./processSamp.sh $TUMOR $TUMOR_R1 $TUMOR_R2
#QSYNC PROCESS_SAMP
exit

echo "##TS:PP3:" `date`
./callPairs.sh out/${NORMAL}/${NORMAL}__RG,MD,QFlt30.bam out/${TUMOR}/${TUMOR}__RG,MD,QFlt30.bam
echo "##TS:PP4:" `date`

