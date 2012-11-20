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
    -o ${OBASE}_UGT_SNP__${MBQ},${CALLC}.vcf


$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_INDEL.txt \
    -glm INDEL \
    -stand_call_conf $CALLC \
    -stand_emit_conf $CALLC \
    -dcov 500 \
    -I $BAM \
    -o ${OBASE}_UGT_INDEL.vcf

$GATK -T VariantFiltration \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    --mask ${OBASE}_UGT_INDEL.vcf --maskName nearIndel \
    --variant ${OBASE}_UGT_SNP__${MBQ},${CALLC}.vcf \
    -o ${OBASE}_UGT_SNP__VF__${MBQ},${CALLC}.vcf \
    --clusterWindowSize 10 \
    --filterExpression 'MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)' --filterName "HARD_TO_VALIDATE" \
    --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
    --filterExpression "QUAL < 50" --filterName "QualFilter"

