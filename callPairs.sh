#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

NORMAL=$1
TUMOR=$2

#
# Deals with an issue on the isilon
#
#source bin/funcs.sh
#checkFile $NORMAL
#checkFile $TUMOR
#checkFile ${NORMAL%%.bam}.bai
#checkFile ${TUMOR%%.bam}.bai
#echo "FILES CHECKED"

SAMPLE_NORMAL=$(echo $NORMAL | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
SAMPLE_TUMOR=$(echo $TUMOR | perl -ne 'm[out/(.*?)(___MERGE|/)];print $1')
OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}
mkdir -p $OBASE

echo "------------------------------------------------------------------"
echo "callPairs"
echo "NORMAL, TUMOR=" $NORMAL, $TUMOR
echo "OBASE=" $OBASE

source $SDIR/bin/paths.sh
source $SDIR/data/dataPaths.sh
source $SDIR/bin/defs.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA_BIG -Xms256m -XX:-UseGCOverheadLimit -jar $GATKJAR "

TARGET_REGION=$SDIR/data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE_SRTChr.bed
KNOWN_SNPS=$SDIR/data/UCSC_dbSNP128_MM9__SRTChr.bed.gz

CHROMS=$($SAMTOOLS view -H $NORMAL | fgrep '@SQ' \
    | awk '{print $2}' | sed 's/SN://' | egrep -v "(_)")
echo "CHROMS=" $CHROMS
if [ -z "$CHROMS" ]; then
	echo "CHROMS<if>=" $CHROMS
	exit
fi

# Realign target creator

source $SDIR/bin/sge.sh

QRUN () {
    ALLOC=$1
    shift
    RET=$(qsub -pe alloc $ALLOC -N $QTAG -v HJV_ROOT=$HJV_ROOT $SDIR/bin/sgeWrap.sh $*)
    echo "#QRUN RET=" $RET
}

SYNC () {
    $QSYNC $QTAG
}

QTAG=q_10_gRTV_$OBASE
for CHROM in $CHROMS; do
QRUN 6 \
    $GATK -T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $CHROM -S LENIENT \
	-o ${OBASE}/${CHROM}___output.intervals \
	-I $NORMAL -I $TUMOR
done
SYNC

QTAG=q_11_gIR_$OBASE
for CHROM in $CHROMS; do
QRUN 6 \
    $GATK -T IndelRealigner \
	-R $GENOME_FASTQ \
	-L $CHROM -S LENIENT \
	-targetIntervals ${OBASE}/${CHROM}___output.intervals \
	--maxReadsForRealignment 500000 --maxReadsInMemory 3000000 \
	-I $NORMAL -I $TUMOR \
	-o ${OBASE}/${CHROM}___Realign.bam
done
SYNC

# CountCovariates

INPUTS=$(ls ${OBASE}/*___Realign.bam | awk '{print "-I "$1}')

QTAG=q_12_gCC_$OBASE
QRUN 12 \
$GATK_BIG -T CountCovariates -l INFO -nt 24 \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION \
	-S LENIENT \
	-cov ReadGroupCovariate \
	-cov QualityScoreCovariate \
	-cov CycleCovariate \
	-cov DinucCovariate \
	-cov MappingQualityCovariate \
	-cov MinimumNQSCovariate \
	--knownSites:BED $KNOWN_SNPS \
	-I $INPUTS \
	-recalFile ${OBASE}/_recal_data.csv

SYNC

# Recalibrate
QTAG=q_13_gTblR_$OBASE
for BAM in ${OBASE}/*___Realign.bam; do
    CHROM=$(echo $BAM | sed 's/.*chr/chr/' | sed 's/___.*//')
    fgrep -w $CHROM $TARGET_REGION >${OBASE}/${CHROM}__TARGET.bed
    QRUN 6 \
    $GATK_BIG -T TableRecalibration -l INFO \
    	-R $GENOME_FASTQ \
    	-L ${OBASE}/${CHROM}__TARGET.bed \
        -S LENIENT \
    	-recalFile ${OBASE}/_recal_data.csv \
    	-I ${BAM} \
    	-o ${BAM%.bam},Recal.bam
done
SYNC

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

#
# Can use threads command
# -nt 20
#

QTAG=q_14_gUGT_$OBASE
QRUN 12 \
$GATK -T UnifiedGenotyper -nt 24 \
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

SYNC

# Need to merge for annoteVCF.py

BAMS=$(ls ${OBASE}/*Realign,Recal.bam | awk '{print "I="$1}')

$PICARD MergeSamFiles CREATE_INDEX=true SO=coordinate O=${OBASE}_Realign,Recal.bam $BAMS

#
# Fix .bai for pysam
ln -s ${OBASE}_Realign,Recal.bai ${OBASE}_Realign,Recal.bam.bai

$SDIR/bin/annoteVCF.py ${SBASE}_UGT_SNP.vcf ${OBASE}_Realign,Recal.bam $MBQ >${SBASE}_UGT_SNP_AnnoteQDP.vcf
$SDIR/bin/getSomaticEvents.py ${SBASE}_UGT_SNP_AnnoteQDP.vcf $SAMPLE_NORMAL $SAMPLE_TUMOR >${SBASE}_UGT_SNP___EVT.txt

