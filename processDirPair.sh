#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )" 

NORMAL=$1
NORMALDIR=$2
TUMOR=$3
TUMORDIR=$4

function processDir {

    SAMP=$1
    DIR=$2

    for R1 in $DIR/*R1*gz; do
		R2=${R1/_R1_/_R2_}
        $SDIR/processSamp.sh $SAMP $R1 $R2
    done

}

#!#processDir $NORMAL $NORMALDIR
#!#processDir $TUMOR $TUMORDIR

# MERGE

#!#echo "MERGE..."
#!#$SDIR/mergeSplitBAMs.sh $NORMAL
#!#$SDIR/mergeSplitBAMs.sh $TUMOR
#!#echo "...Merge done"

$SDIR/callPairs.sh out/${NORMAL}___MERGE,MD.bam out/${TUMOR}___MERGE,MD.bam
