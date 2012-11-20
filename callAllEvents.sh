#!/bin/bash

source bin/paths.sh
source data/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "

BAM=$1
OBASE=$(basename $BAM | sed 's/_Realign.*//')
echo $OBASE

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE.bed
MBQ=17
CALLC=30

# Unified Genotyper
$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_SNP.txt \
    -glm SNP \
    -stand_call_conf $CALLC \
    -stand_emit_conf $CALLC \
    -dcov 500 \
    -mbq $MBQ \
    -I $BAM \
    --output_mode EMIT_ALL_SITES \
	-o ${OBASE}_UGT_SNP__${MBQ},${CALLC}.vcf

