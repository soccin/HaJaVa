#!/bin/bash

source bin/paths.sh
source bin/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "

NORMAL=$1
TUMOR=$2

SAMPLE_NORMAL=$(basename $NORMAL | perl -ne 'm/(.*)___/;print $1')
SAMPLE_TUMOR=$(basename $TUMOR | perl -ne 'm/(.*)___/;print $1')
OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}

echo $NORMAL $TUMOR
echo $OBASE

TARGET_REGION=data/HaJaVa__GoldSet_V7__TARGETED__Clean___TARGETS.bed

# Unified Genotyper
$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_SNP__GS.txt \
    -glm SNP \
    --output_mode EMIT_ALL_SITES \
    -dcov 500 \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${OBASE}_UGT_SNP__GS.vcf

