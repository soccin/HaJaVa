#!/bin/bash

DATADIR=../test/SeqData
echo "##TS::" `date`
./processPair.sh \
	K16739-Lung $DATADIR/LID46442___MERGE___R1.fastq.gz $DATADIR/LID46442___MERGE___R2.fastq.gz \
	K16739-T1 $DATADIR/LID46443___MERGE___R1.fastq.gz $DATADIR/LID46443___MERGE___R2.fastq.gz

echo "##TS::" `date`

./callPairs.sh \
	out/K16739-Lung/LID46442___MERGE___R1__RG,MD,QFlt30.bam \
	out/K16739-T1/LID46443___MERGE___R1__RG,MD,QFlt30.bam

echo "##TS::" `date`

