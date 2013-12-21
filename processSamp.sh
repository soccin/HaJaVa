#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/bin/paths.sh
source $SDIR/bin/defs.sh

source $SDIR/data/dataPaths.sh

SAMPLE=$1
R1=$2
R2=$3
ODIR=out/${SAMPLE}
ODIR1=out
TAG=$(basename ${R1} | sed 's/.fast.*//')

mkdir -p ${ODIR}

$SDIR/doMapping.sh $R1 $R2 $SAMPLE $SAMPLE $TAG $SAMPLE

#echo "BREAK::processSamp.sh LINE 20"; exit

$PICARD MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
	I=$ODIR/${TAG}__RG.bam \
	O=$ODIR/${TAG}__RG,MD.bam \
	M=$ODIR/${TAG}__RG,MD.txt

$SAMTOOLS view -b -q 30 \
	$ODIR/${TAG}__RG,MD.bam \
	> $ODIR/${TAG}__RG,MD,QFlt30.bam

$PICARD BuildBamIndex I=$ODIR/${TAG}__RG,MD,QFlt30.bam
md5sum $ODIR/${TAG}__RG,MD,QFlt30.bam >$ODIR/${TAG}__RG,MD,QFlt30.bam.MD5
