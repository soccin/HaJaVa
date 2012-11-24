#!/bin/bash

NORMAL=$1
TUMOR=$2

SAMPLE_NORMAL=$(echo $NORMAL | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
SAMPLE_TUMOR=$(echo $TUMOR | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}
echo "NORMAL, TUMOR=" $NORMAL, $TUMOR
echo "OBASE=" $OBASE

source bin/paths.sh
source data/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE_SRTChr.bed
KNOWN_SNPS=data/UCSC_dbSNP128_MM9__SRTChr.bed.gz

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
	--knownSites:BED $KNOWN_SNPS \
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

##
# GATK PARAMETERS
#
MBQ=17
DCOV=500
STAND_CALL_CONF=30
STAND_EMIT_CONF=30

SBASE=${OBASE}___MBQ_${MBQ}__CCONF_${STAND_CALL_CONF}

$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${SBASE}___METRICS_FILE_SNP.txt \
    -glm SNP \
    -stand_call_conf $STAND_CALL_CONF \
    -stand_emit_conf $STAND_EMIT_CONF \
    -dcov $DCOV \
    -mbq $MBQ \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${SBASE}_UGT_SNP.vcf

#
# Fix .bai for pysam
ln -s ${OBASE}_Realign,Recal.bai ${OBASE}_Realign,Recal.bam.bai

bin/annoteVCF.py ${SBASE}_UGT_SNP.vcf ${OBASE}_Realign,Recal.bam $MBQ >${SBASE}_UGT_SNP_AnnoteQDP.vcf
./bin/getSomaticEvents.py ${SBASE}_UGT_SNP_AnnoteQDP.vcf $SAMPLE_NORMAL $SAMPLE_TUMOR >${SBASE}_UGT_SNP___EVT.txt
exit

$GATK -T UnifiedGenotyper -nt 12 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${SBASE}___METRICS_FILE_INDEL.txt \
    -glm INDEL \
    -stand_call_conf $STAND_CALL_CONF \
    -stand_emit_conf $STAND_EMIT_CONF \
    -dcov $DCOV \
    -I ${OBASE}_Realign,Recal.bam \
    -o ${SBASE}_UGT_INDEL.vcf

$GATK -T VariantFiltration \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    --mask ${SBASE}_UGT_INDEL.vcf --maskName nearIndel \
    --variant ${SBASE}_UGT_SNP.vcf \
    -o ${SBASE}_UGT_SNP_VF.vcf \
    --clusterWindowSize 10 \
    --filterExpression 'MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)' --filterName "HARD_TO_VALIDATE" \
    --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
    --filterExpression "QUAL < $STAND_CALL_CONF" --filterName "QualFilter"

$GATK -T VariantFiltration \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION \
    --variant  ${SBASE}_UGT_INDEL.vcf \
    -o  ${SBASE}_UGT_INDEL_VF.vcf \
    --clusterWindowSize 10 \
    --filterExpression 'MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)' --filterName "HARD_TO_VALIDATE" \
    --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
    --filterExpression "QUAL < $STAND_CALL_CONF" --filterName "QualFilter"
