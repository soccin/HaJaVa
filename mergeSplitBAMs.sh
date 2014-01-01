#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/bin/paths.sh
source $SDIR/bin/defs.sh

SAMPLE=$1
SAMPLE=$(echo $SAMPLE | sed 's/\/$//' | perl -F"/" -ane '$x=$F[$#F];chomp($x);print $x')
echo $SAMPLE

#
# Test that pairs were done correctly
#
BADCLIPPAIRS=$(find out/$SAMPLE/*fastq.MD5 | xargs cat | sort  | uniq -c | awk '$1!=2{print $0}')
if [ -n "$BADCLIPPAIRS" ]; then
    echo "ERROR IN CLIP rePAIRING"
    echo $BADCLIPPAIRS
    exit
fi

INPUTBAMS=$(find out/$SAMPLE/*QFlt30.bam | awk '{print "I="$1}')
cat out/$SAMPLE/*QFlt30.bam.MD5 > out/${SAMPLE}__BAMs.MD5
SIGOK=$(md5sum -c out/${SAMPLE}__BAMs.MD5 | fgrep FAILED)

if [ -n "$SIGOK" ]; then
    echo "INVALID BAM MD5 SIGNATURE"
    echo $SIGOK
    echo "TERMINATING MERGE OF" $SAMPLE
    exit
fi

$PICARD MergeSamFiles O=out/${SAMPLE}___MERGE.bam SO=coordinate CREATE_INDEX=true $INPUTBAMS

$PICARD MarkDuplicates I=out/${SAMPLE}___MERGE.bam CREATE_INDEX=true REMOVE_DUPLICATES=true \
	MAX_RECORDS_IN_RAM=5000000 \
  O=out/${SAMPLE}___MERGE,MD.bam M=out/${SAMPLE}___MERGE,MD.txt
