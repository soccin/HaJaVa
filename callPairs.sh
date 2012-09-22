#!/bin/bash

source bin/paths.sh

NORMAL=$1
TUMOR=$2

SAMPLE_NORMAL=$(basename $NORMAL | perl -ne 'm/___(.*)___RG/;print $1')
SAMPLE_TUMOR=$(basename $TUMOR | perl -ne 'm/___(.*)___RG/;print $1')
OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}

echo $NORMAL $TUMOR
echo $OBASE

# Realign target creator

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE.bed 

GATK="$JAVA -jar $GATKJAR -et NO_ET -K socci_cbio.mskcc.org.key "

#if [ -z "DO NOT RUN" ]; then

$GATK -T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-o ${OBASE}_output.intervals \
	-I $NORMAL -I $TUMOR

exit

# Realign

$GATK -T IndelRealigner \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-targetIntervals ${OBASE}_output.intervals \
	--maxReadsForRealignment 500000 --maxReadsInMemory 3000000 \
	-I $NORMAL -I $TUMOR \
	-o ${OBASE}_Realign.bam

#fi

# CountCovariates

GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR -et NO_ET -K socci_cbio.mskcc.org.key"

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

exit

if [ -z "DO NOT RUN" ]; then

# Recalibrate
/common/sge/bin/lx24-amd64/qsub -P ngs -N kp_25042012_TR -hold_jid kp_25042012_CC_MERGE,kp_25042012_IR -pe alloc 12 /home/mpirun/tools/qCMD /opt/java/jdk1.6.0_16/bin
/java -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -Djava.io.tmpdir=/ifs/data/mpirun/temp -jar $GATK -T TableRecalib
ration -et NO_ET -l INFO -R $GENOME_FASTQ -L chr$c -S LENIENT -recalFile $sln\_$ln\_recal_data.csv -I kp_25042012_CHR$c\_indelR
ealigned.bam -o kp_25042012_CHR$c\_indelRealigned_recal.ba


$JAVA -jar $GATKDIR/GenomeAnalysisTK.jar \
        -T UnifiedGenotyper -nt 8 -et NO_ET \
        -R $GENOME \
        -A DepthOfCoverage -A AlleleBalance \
        -metrics $METRICS_FILE_SNP \
        -stand_call_conf 50.0 \
        -stand_emit_conf 50.0 \
        -dcov 500 \
        -mbq 30 \
        -I $INPUT_BAM \
        -o $OUTPUT_VCF_SNP \
        -glm SNP

$JAVA -jar $GATKDIR/GenomeAnalysisTK.jar \
        -T UnifiedGenotyper -nt 8 -et NO_ET \
        -R $GENOME \
        -A DepthOfCoverage -A AlleleBalance \
        -metrics $METRICS_FILE_INDEL \
        -stand_call_conf 50.0 \
        -stand_emit_conf 50.0 \
        -dcov 500 \
        -I $INPUT_BAM \
        -o $OUTPUT_VCF_INDEL \
        -glm INDEL

$JAVA -jar $GATKDIR/GenomeAnalysisTK.jar \
        -T VariantFiltration -et NO_ET -R $GENOME \
        --mask $OUTPUT_VCF_INDEL --maskName nearIndel \
        --variant $OUTPUT_VCF_SNP \
        -o $OUTPUT_VCF_SNP_VF \
        --clusterWindowSize 10 \
        --filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" --filterName "HARD_TO_VALIDATE" \
        --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
        --filterExpression "QUAL < 50" --filterName "QualFilter" 

$JAVA -jar $GATKDIR/GenomeAnalysisTK.jar \
        -T VariantFiltration -et NO_ET -R $GENOME \
        --variant $OUTPUT_VCF_INDEL \
        -o $OUTPUT_VCF_INDEL_VF \
        --clusterWindowSize 10 \
        --filterExpression "MQ0 >= 4 && ((MQ0 / (1.0 * DP)) > 0.1)" --filterName "HARD_TO_VALIDATE" \
        --filterExpression "SB >= -1.0" --filterName "StrandBiasFilter" \
        --filterExpression "QUAL < 50" --filterName "QualFilter"

fi

