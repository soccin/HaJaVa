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

# Realign target creator

$GATK -T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-o ${OBASE}_output.intervals \
	-I $NORMAL -I $TUMOR

# Realign

$GATK -T IndelRealigner \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-targetIntervals ${OBASE}_output.intervals \
	--maxReadsForRealignment 500000 --maxReadsInMemory 3000000 \
	-I $NORMAL -I $TUMOR \
	-o ${OBASE}_Realign.bam

# CountCovariates

$GATK_BIG -T CountCovariates -l INFO \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION \
	-S LENIENT -nt 12 \
	-cov ReadGroupCovariate \
	-cov QualityScoreCovariate \
	-cov CycleCovariate \
	-cov DinucCovariate \
	-cov MappingQualityCovariate \
	-cov MinimumNQSCovariate \
	--knownSites:BED data/UCSC_dbSNP128_MM9__SRT.bed \
	-I ${OBASE}_Realign.bam \
	-recalFile ${OBASE}_recal_data.csv


# Recalibrate
$GATK_BIG -T TableRecalibration -l INFO \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-recalFile ${OBASE}_recal_data.csv \
	-I ${OBASE}_Realign.bam \
	-o ${OBASE}_Realign,Recal.bam


# Unified Genotyper
$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_SNP.txt \
    -glm SNP \
    -stand_call_conf 50.0 \
    -stand_emit_conf 50.0 \
    -dcov 500 \
    -mbq 30 \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${OBASE}_UGT_SNP.vcf


$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${OBASE}___METRICS_FILE_INDEL.txt \
    -glm INDEL \
    -stand_call_conf 50.0 \
    -stand_emit_conf 50.0 \
    -dcov 500 \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${OBASE}_UGT_INDEL.vcf

$GATK -T VariantFiltration \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    --mask ${OBASE}_UGT_INDEL.vcf --maskName nearIndel \
    --variant ${OBASE}_UGT_SNP.vcf \
    -o ${OBASE}_UGT_SNP_VF.vcf \
    --clusterWindowSize 10 \
    --filterExpression 'MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)' --filterName "HARD_TO_VALIDATE" \
    --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
    --filterExpression "QUAL < 50" --filterName "QualFilter"

$GATK -T VariantFiltration \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION \
    --variant  ${OBASE}_UGT_INDEL.vcf \
    -o  ${OBASE}_UGT_INDEL_VF.vcf \
    --clusterWindowSize 10 \
    --filterExpression 'MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)' --filterName "HARD_TO_VALIDATE" \
    --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
    --filterExpression "QUAL < 50" --filterName "QualFilter"
