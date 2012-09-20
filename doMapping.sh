#!/bin/bash

# 
# This script does all the processing that can be done on a single sample
# 
#   Clip
#   BWA (aln, sampe)
#   RG
#   Drop Duplicates
#
# This version expects two input files (FASTQ UNCOMPRESSED)
#    R1.fastq
#    R2.fastq
#
# Output a single BAM file.
#
# ARGS
#   R1.fastq
#   R2.fastq
#   SampleName (for RG)
#   LibName 
#   PUnit
#   RG_ID
#
#   We assume the platform is Illumina for RG


###
# LOCAL PATHS THAT NEED TO BE FIXED
#

JAVA="/opt/java/jdk1.6.0_16/bin/java "
BWA=/home/socci/bin/bwa
PICARDDIR=/ifs/data/bio/bin/picard-tools-1.55
TMPDIR=/scratch/socci

GENOME_DIR="/ifs/data/bio/Genomes/M.musculus/mm9"
GENOME_TAG=mouse_mm9__FULL_hEGFR

###
# These variable must point to the genome fasta file and the BWA index

GENOME_FASTQ=$GENOME_DIR/${GENOME_TAG}.fa
GENOME_BWA=$GENOME_DIR/BWA/DNA/$GENOME_TAG

###

SDIR=$(dirname $0)
BIN=$SDIR/bin/`uname -m`
JAVABIN=$SDIR/bin/java


function PICARD {
	JAR=$1
	shift
	$JAVA -Xmx32g -Djava.io.tmpdir=/scratch/socci -jar $PICARDDIR/$JAR.jar \
			TMP_DIR=/scratch/socci VALIDATION_STRINGENCY=LENIENT $*
}

##PICARD MarkDuplicates I=XXX O=XXX

####
####
####
 
ADAPTER=AGATCG

FASTQ1=$1
FASTQ2=$2

SAMPLENAME=$3
LIBNAME=$4
PUNIT=$5
RGID=$6

ODIR=out/${LIBNAME}
BASE1=$(basename $FASTQ1)
BASE1=$ODIR/${BASE1%%.*}
BASE2=$(basename $FASTQ2)
BASE2=$ODIR/${BASE2%%.*}

mkdir -p $ODIR

echo $BASE1, $BASE2

OUT1=${BASE1}__clip.fastq
OUT2=${BASE2}__clip.fastq

$JAVA -jar $JAVABIN/HaJaVa-ClipAdapter.jar $FASTQ1 $FASTQ2 \
    $OUT1 $OUT2 $ADAPTER

IN1=$OUT1
IN2=$OUT2
OUT1=${OUT1%%.*}.aln
OUT2=${OUT2%%.*}.aln


$BWA aln -t 20 $GENOME_BWA $IN1 >$OUT1
$BWA aln -t 20 $GENOME_BWA $IN2 >$OUT2

OUT12=$ODIR/${RGID}__${SAMPLENAME}.sam

$BWA sampe -f $OUT12 $GENOME_BWA $OUT1 $OUT2 $IN1 $IN2

PICARD AddOrReplaceReadGroups I=$OUT12 O=${OUT12%%.sam}__RG.bam CREATE_INDEX=true SO=coordinate \
	ID=$RGID PL=illumina LB=$LIBNAME PU=$PUNIT SM=$SAMPLENAME

rm $IN1 $IN2 $OUT1 $OUT2 $OUT12
