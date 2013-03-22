#!/bin/bash

NORMAL=$1
NORMALDIR=$2
TUMOR=$3
TUMORDIR=$4

source bin/sge.sh

SAMP=$NORMAL
DIR=$NORMALDIR

TAG=q_DIR__${NORMAL}___${TUMOR}

function processDir {

    SAMP=$1
    DIR=$2

NUM=0

    for R1 in $DIR/*R1*gz; do
	
NUM=$(( $NUM + 1 ))
echo $NUM, $file
STATUS=$(./throttle.py $NUM)

if [ -n "$STATUS" ]; then
echo "HOLD"
sleep 1200
fi	

		R2=${R1/_R1_/_R2_}
        ##echo \
        #qsub -N $TAG $QCMD \
        ./processSamp.sh $SAMP $R1 $R2
    done

}

processDir $NORMAL $NORMALDIR
processDir $TUMOR $TUMORDIR
#QSYNC $TAG

# MERGE

echo "MERGE..."
#qsub -N ${TAG}_2 $QCMD \
./mergeSplitBAMs.sh $NORMAL
#qsub -N ${TAG}_2 $QCMD \
./mergeSplitBAMs.sh $TUMOR
#QSYNC ${TAG}_2

echo "...Merge done"

./callPairs.sh out/${NORMAL}___MERGE,MD.bam out/${TUMOR}___MERGE,MD.bam

