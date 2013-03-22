#!/bin/bash

NORMAL=$1
TUMOR=$2

source bin/funcs.sh
checkFile $NORMAL
checkFile $TUMOR
checkFile ${NORMAL%%.bam}.bai
checkFile ${TUMOR%%.bam}.bai
echo "FILES CHECKED"

SAMPLE_NORMAL=$(echo $NORMAL | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
SAMPLE_TUMOR=$(echo $TUMOR | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}
mkdir -p $OBASE

echo "------------------------------------------------------------------"
echo "callPairs"
echo "NORMAL, TUMOR=" $NORMAL, $TUMOR
echo "OBASE=" $OBASE

source bin/paths.sh
source bin/sge.sh
source data/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE_SRTChr.bed
KNOWN_SNPS=data/UCSC_dbSNP128_MM9__SRTChr.bed.gz

CHROMS=$(samtools view -H $NORMAL | fgrep '@SQ' | awk '{print $2}' | sed 's/SN://' | egrep -v "(_)")
echo "CHROMS=" $CHROMS
if [ -z "$CHROMS" ]; then
	echo "CHROMS<if>=" $CHROMS
	exit
fi

# Realign target creator

QTAG=q_RTC_${OBASE}

for CHROM in $CHROMS; do
  #qsub -pe alloc 4 -N $QTAG $QCMD \
    $GATK -T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $CHROM -S LENIENT \
	-o ${OBASE}/${CHROM}___output.intervals \
	-I $NORMAL -I $TUMOR
done
#QSYNC $QTAG

# Realign

QTAG=q_IR_${OBASE}
echo
echo $QTAG
echo
for CHROM in $CHROMS; do
  #qsub -pe alloc 4 -N $QTAG $QCMD \
    $GATK -T IndelRealigner \
	-R $GENOME_FASTQ \
	-L $CHROM -S LENIENT \
	-targetIntervals ${OBASE}/${CHROM}___output.intervals \
	--maxReadsForRealignment 500000 --maxReadsInMemory 3000000 \
	-I $NORMAL -I $TUMOR \
	-o ${OBASE}/${CHROM}___Realign.bam
done
#QSYNC $QTAG

# CountCovariates

INPUTS=$(ls ${OBASE}/*___Realign.bam | awk '{print "-I "$1}')
QTAG=q_CCOV_${OBASE}
echo
echo $QTAG
echo
#qsub -pe alloc 9 -N $QTAG $QCMD \
$GATK_BIG -T CountCovariates -l INFO \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION \
	-S LENIENT -nt 20 \
	-cov ReadGroupCovariate \
	-cov QualityScoreCovariate \
	-cov CycleCovariate \
	-cov DinucCovariate \
	-cov MappingQualityCovariate \
	-cov MinimumNQSCovariate \
	--knownSites:BED $KNOWN_SNPS \
	-I $INPUTS \
	-recalFile ${OBASE}/_recal_data.csv
#QSYNC $QTAG

# Recalibrate
QTAG=q_TR_${OBASE}
for BAM in ${OBASE}/*___Realign.bam; do
    CHROM=$(echo $BAM | sed 's/.*chr/chr/' | sed 's/___.*//')
    fgrep -w $CHROM $TARGET_REGION >${OBASE}/${CHROM}__TARGET.bed
    #qsub -pe alloc 5 -N $QTAG $QCMD \
        $GATK_BIG -T TableRecalibration -l INFO \
        	-R $GENOME_FASTQ \
        	-L ${OBASE}/${CHROM}__TARGET.bed \
            -S LENIENT \
        	-recalFile ${OBASE}/_recal_data.csv \
        	-I ${BAM} \
        	-o ${BAM%.bam},Recal.bam
done
#QSYNC $QTAG

# Unified Genotyper

##
# GATK PARAMETERS
#
MBQ=17
DCOV=500
STAND_CALL_CONF=30
STAND_EMIT_CONF=30

SBASE=${OBASE}___MBQ_${MBQ}__CCONF_${STAND_CALL_CONF}
INPUTS=$(ls ${OBASE}/*___Realign,Recal.bam | awk '{print "-I "$1}')

QTAG=q_UGT_SNP_${OBASE}
#qsub -pe alloc 9 -N $QTAG $QCMD \
$GATK -T UnifiedGenotyper -nt 20 \
    -R $GENOME_FASTQ \
	-L $TARGET_REGION \
    -A DepthOfCoverage -A AlleleBalance \
    -metrics ${SBASE}___METRICS_FILE_SNP.txt \
    -glm SNP \
    -stand_call_conf $STAND_CALL_CONF \
    -stand_emit_conf $STAND_EMIT_CONF \
    -dcov $DCOV \
    -mbq $MBQ \
    $INPUTS \
    -o ${SBASE}_UGT_SNP.vcf

# Need to merge for annoteVCF.py

BAMS=$(ls ${OBASE}/*Realign,Recal.bam | awk '{print "I="$1}')
#qsub -pe alloc 6 -N $QTAG $QCMD \
picard MergeSamFiles CREATE_INDEX=true SO=coordinate O=${OBASE}_Realign,Recal.bam $BAMS

#QSYNC $QTAG

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

