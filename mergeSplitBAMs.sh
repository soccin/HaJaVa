#!/bin/bash

source bin/paths.sh
source bin/defs.sh

SAMPLE=$1
SAMPLE=$(echo $SAMPLE | sed 's/\/$//' | pyp 's[-1]')
echo $SAMPLE

BADCLIPPAIRS=$(find out/$SAMPLE/*.MD5 | xargs cat | sort  | uniq -c | awk '$1!=2{print $0}')

if [ -n "$BADCLIPPAIRS" ]; then
    echo "ERROR IN CLIP rePAIRING"
    echo $BADCLIPPAIRS
    exit
fi

INPUTBAMS=$(find out/$SAMPLE/*QFlt30.bam | awk '{print "I="$1}')

#qsub -pe alloc 6 -N pic.MERGE__${SAMPLE} $QCMD \
  $PICARD MergeSamFiles O=out/${SAMPLE}___MERGE.bam SO=coordinate CREATE_INDEX=true $INPUTBAMS
#QSYNC pic.MERGE__${SAMPLE}

#qsub -pe alloc 6 -N pic.MD__${SAMPLE} $QCMD \
  $PICARD MarkDuplicates I=out/${SAMPLE}___MERGE.bam CREATE_INDEX=true REMOVE_DUPLICATES=true \
  O=out/${SAMPLE}___MERGE,MD.bam M=out/${SAMPLE}___MERGE,MD.txt
