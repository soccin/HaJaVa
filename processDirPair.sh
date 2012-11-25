#!/bin/bash

NORMAL=$1
NORMALDIR=$2
TUMOR=$3
TUMORDIR=$4

source bin/paths.sh
source data/dataPaths.sh
source bin/sge.sh

SAMP=$NORMAL
DIR=$NORMALDIR

TAG=q_DIR__${NORMAL}___${TUMOR}

function processDir {

    SAMP=$1
    DIR=$2

    for R1 in $DIR/*R1*gz; do
        R2=${R1/_R1_/_R2_}
        echo \
        qsub -N $TAG $QCMD \
        ./processSamp.sh $SAMP $R1 $R2
    done

}

processDir $NORMAL $NORMALDIR
processDir $TUMOR $TUMORDIR
$QSYNC $TAG

# MERGE

# CALL

