#!/bin/bash

DATADIR=../test/SeqData
echo "##TS::" `date`
./processPair.sh \
	K16739-Lung $DATADIR/LID46442___MERGE___R1.fastq.gz $DATADIR/LID46442___MERGE___R2.fastq.gz \
	K16739-T1 $DATADIR/LID46443___MERGE___R1.fastq.gz $DATADIR/LID46443___MERGE___R2.fastq.gz

echo "##TS::" `date`
