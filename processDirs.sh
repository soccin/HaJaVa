#!/bin/bash

SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/bin/sge.sh

function processDir {

    SAMP=$1
    DIR=$2
    TAG=qq_01_DIR__${SAMP}

    for R1 in $DIR/*R1*gz; do
        R2=${R1/_R1_/_R2_}
        qsub -pe alloc 8 -N $TAG \
        -v HJV_ROOT=$HJV_ROOT $QCMD \
            $SDIR/processSamp.sh $SAMP $R1 $R2
    done

#    echo "BREAK: processDirs.sh Line 19"; exit

}

DIRLIST=$1

if [ -z "$HJV_ROOT" ]; then
    echo "You need to set the environment variable HJV_ROOT"
    echo "Please read installation instructions"
    exit
fi

for rec in $(cat $DIRLIST); do
	SAMPLENAME=$(echo $rec | awk -F';' '{print $1}')
	SAMPLEDIR=$(echo $rec | awk -F';' '{print $2}')
    TAG1=qq_01_DIR__${SAMPLENAME}
    TAG2=qq_02_MERGE__${SAMPLENAME}
    processDir $SAMPLENAME $SAMPLEDIR
    qsub -pe alloc 6 \
    -N $TAG2 -hold_jid $TAG1 -v HJV_ROOT=$HJV_ROOT $QCMD \
        $SDIR/mergeSplitBAMs.sh $SAMPLENAME
done
