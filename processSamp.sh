#!/bin/bash

source bin/paths.sh

DROOT=/ifs/res/socci/Data/HaJaVa/11.10.12

LIB=$1
SAMPLE=$2

ODIR=out/${LIB}
ODIR1=out

mkdir -p ${ODIR}

for R1 in $(ls $DROOT/Sample_$LIB/*R1*gz | head -3); do
	R2=${R1/_R1_/_R2_}
	B1=$(basename $R1 | sed 's/.gz//')
	B2=$(basename $R2 | sed 's/.gz//')
	echo $B2, $B2
	if [ -z "1" ]; then
		qsub -N qZCAT_${LIB} -pe alloc 2 $SGE/qCMD \
		  zcat $R1 \>${ODIR}/$B1
		qsub -N qZCAT_${LIB} -pe alloc 2 $SGE/qCMD \
		  zcat $R2 \>${ODIR}/$B2
	    $SGE/qSYNC qZCAT_${LIB}
	else	
		zcat $R1 | head -8000 >${ODIR}/$B1
		zcat $R2 | head -8000 >${ODIR}/$B2
	fi
	TAG=${B1/_R1_/__}
	TAG=${TAG%%.*}
	qsub -N qDOMAP_${LIB} -pe alloc 4 $SGE/qCMD ./doMapping.sh \
	    ${ODIR}/$B1 ${ODIR}/$B2 $SAMPLE $LIB $TAG $TAG
done
$SGE/qSYNC qDOMAP_${LIB}


INPUTS=$(ls ${ODIR}/*.bam | awk '{print "I="$1}')
qsub -pe alloc 4 -N qMERGE_${LIB} $SGE/qCMD \
    $PICARD MergeSamFiles SO=coordinate CREATE_INDEX=true \
    O=$ODIR1/${LIB}___${SAMPLE}___RG,Merge.bam $INPUTS
$SGE/qSYNC qMERGE_${LIB}

qsub -pe alloc 4 -N qMD_${LIB} $SGE/qCMD \
    $PICARD MarkDuplicates REMOVE_DUPLICATES=true CREATE_INDEX=true \
		I=$ODIR1/${LIB}___${SAMPLE}___RG,Merge.bam \
		O=$ODIR1/${LIB}___${SAMPLE}___RG,Merge,MD.bam \
		M=$ODIR1/${LIB}___${SAMPLE}___RG,Merge,MD.txt
$SGE/qSYNC qMD_${LIB}

qsub -pe alloc 3 -N qSAMTOOLS_${LIB} $SGE/qCMD \
    samtools view -b -q 30 \
      $ODIR1/${LIB}___${SAMPLE}___RG,Merge,MD.bam \
      \> $ODIR1/${LIB}___${SAMPLE}___RG,Merge,MD,QFlt30.bam
$SGE/qSYNC qSAMTOOLS_${LIB}

qsub -pe alloc 3 -N qINDEX_${LIB} $SGE/qCMD \
	$PICARD BuildBamIndex \
	  I=$ODIR1/${LIB}___${SAMPLE}___RG,Merge,MD,QFlt30.bam
