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

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE.bed


# Unified Genotyper
$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_SNP.txt \
    -glm SNP \
    -stand_call_conf 30.0 \
    -stand_emit_conf 30.0 \
    -dcov 500 \
    -mbq 17 \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${OBASE}_UGT_SNP__cConf_30__mbq_17.vcf


$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_INDEL.txt \
    -glm INDEL \
    -stand_call_conf 30.0 \
    -stand_emit_conf 30.0 \
    -dcov 500 \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${OBASE}_UGT_INDEL__cConf_30__mbq_17.vcf
