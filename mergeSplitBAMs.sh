#!/bin/bash

source bin/sge.sh

SAMPLE=$1

BADCLIPPAIRS=$(find out/$SAMPLE/*.MD5 | xargs cat | sort  | uniq -c | awk '$1!=2{print $0}')

if [ -n "$BADCLIPPAIRS" ]; then
    echo "ERROR IN CLIP rePAIRING"
    echo $BADCLIPPAIRS
    exit
fi

INPUTBAMS=$(find out/$SAMPLE/*QFlt30.bam | awk '{print "I="$1}')

qsub -pe alloc 4 -N pic.MERGE__${SAMPLE} $QCMD \
  picard MergeSamFiles O=${SAMPLE}___MERGE.bam SO=coordinate CREATE_INDEX=true $INPUTBAMS
$QSYNC pic.MERGE__${SAMPLE}

qsub -pe alloc 4 -N pic.MD__${SAMPLE} $QCMD \
  picard MarkDuplicates I=${SAMPLE}___MERGE.bam CREATE_INDEX=true REMOVE_DUPLICATES=true \
  O=${SAMPLE}___MERGE,MD.bam M=${SAMPLE}___MERGE,MD.txt
