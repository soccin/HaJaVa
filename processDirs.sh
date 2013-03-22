#!/bin/bash

source bin/sge.sh

function processDir {

    SAMP=$1
    DIR=$2

    NUM=$(./num8nodes.sh)
    echo "NUM=" $NUM

    for R1 in $DIR/*R1*gz; do
		DELAY=$(cat SGE_DELAY)
		echo "DELAY="$DELAY
        echo $NUM, $file
        while [ $NUM -lt 1 ]; do
            echo "Sleeping ..."
            ./sgeUtilization.sh
			sleep `./sgeUtilization.sh`
            NUM=$(./num8nodes.sh)
            echo $NUM
        done

        ./sgeUtilization.sh

        R2=${R1/_R1_/_R2_}
        #echo \
        #qsub -N $TAG $QCMD \
        ./processSamp.sh $SAMP $R1 $R2

        NUM=$(( $NUM - 1 ))
		sleep $DELAY

    done

}

DIRLIST=$1

for rec in $(cat $DIRLIST); do
	SAMPLENAME=$(echo $rec | awk -F';' '{print $1}')
	SAMPLEDIR=$(echo $rec | awk -F';' '{print $2}')
	TAG=q_DIR__${SAMPLENAME}
	processDir $SAMPLENAME $SAMPLEDIR
done
