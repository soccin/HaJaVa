#!/bin/bash
#cat ,testData/sampleKey.txt  | xargs -n 2 ./processSamp.sh  

for file in $(cat ,testData/sampleKey.txt|tr ' ' '/'); do 
	LIB=$(dirname $file)
	SAMP=$(basename $file)
	./processSamp.sh $LIB $SAMP >${LIB}___LOG.txt 2>&1 &
done

