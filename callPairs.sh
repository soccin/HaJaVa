#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ -z "$HJV_ROOT" ]; then
    echo "You need to set the environment variable HJV_ROOT"
    echo "Please read installation instructions"
    exit
fi


SAMPLE_NORMAL=$1
SAMPLE_TUMOR=$2

NORMAL=out/${SAMPLE_NORMAL}___MERGE,MD.bam
TUMOR=out/${SAMPLE_TUMOR}___MERGE,MD.bam

OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}
mkdir -p $OBASE


echo "------------------------------------------------------------------"
echo "callPairs"
echo "NORMAL, TUMOR=" $NORMAL, $TUMOR
echo "OBASE=" $OBASE
echo SAMPLE_NORMAL=$SAMPLE_NORMAL
echo SAMPLE_TUMOR=$SAMPLE_TUMOR
##
# GATK PARAMETERS
#
MBQ=17
DCOV=500
STAND_CALL_CONF=30
STAND_EMIT_CONF=30

SBASE=${OBASE}___MBQ_${MBQ}__CCONF_${STAND_CALL_CONF}

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

QUEUES=mad.q,nce.q

QRUN () {
    ALLOC=$1
    shift
    RET=$(qsub -q $QUEUES -pe alloc $ALLOC -N $QTAG -v HJV_ROOT=$HJV_ROOT $SDIR/bin/sgeWrap.sh $*)
    echo "#QRUN RET=" $RET
}

SYNC () {
    $QSYNC $QTAG
}


#####################################################################################
#####################################################################################
#####################################################################################

QTAG=qq_10_gRTV_$OBASE
for CHROM in $CHROMS; do
QRUN 6 \
    $GATK -T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $CHROM -S LENIENT \
	-o ${OBASE}/${CHROM}___output.intervals \
	-I $NORMAL -I $TUMOR
done
SYNC

QTAG=qq_11_gIR_$OBASE
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

QTAG=qq_12_gCC_$OBASE
QRUN 13 \
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
QTAG=qq_13_gTblR_$OBASE
for BAM in ${OBASE}/*___Realign.bam; do
    CHROM=$(echo $BAM | sed 's/.*chr/chr/' | sed 's/___.*//')
    fgrep -w $CHROM $TARGET_REGION >${OBASE}/${CHROM}__TARGET.bed
    QRUN 6 \
    $GATK -T TableRecalibration -l INFO \
    	-R $GENOME_FASTQ \
    	-L ${OBASE}/${CHROM}__TARGET.bed \
        -S LENIENT \
    	-recalFile ${OBASE}/_recal_data.csv \
    	-I ${BAM} \
    	-o ${BAM%.bam},Recal.bam
done
SYNC

# Unified Genotyper

INPUTS=$(ls ${OBASE}/*___Realign,Recal.bam | awk '{print "-I "$1}')

#
# Can use threads command
# -nt 20
#

QTAG=qq_14_gUGT_$OBASE
QRUN 22 \
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

# Need to merge for annoteVCF.py

BAMS=$(ls ${OBASE}/*Realign,Recal.bam | awk '{print "I="$1}')
QRUN 6 \
$PICARD MergeSamFiles CREATE_INDEX=true SO=coordinate O=${OBASE}_Realign,Recal.bam $BAMS

SYNC

# Fix .bai for pysam
ln -s ${OBASE}_Realign,Recal.bai ${OBASE}_Realign,Recal.bam.bai

$SDIR/bin/annoteVCF.py ${SBASE}_UGT_SNP.vcf ${OBASE}_Realign,Recal.bam $MBQ >${SBASE}_UGT_SNP_AnnoteQDP.vcf
$SDIR/bin/getSomaticEvents.py ${SBASE}_UGT_SNP_AnnoteQDP.vcf $SAMPLE_NORMAL $SAMPLE_TUMOR >${SBASE}_UGT_SNP___EVT.txt


echo "*******************"
echo
echo $SAMPLE_NORMAL
echo $SAMPLE_TUMOR

N_COV_CUT=8
T_COV_CUT=14
N_NRAF_CUT=0.05
T_NRAF_CUT=0.15

N_NRAF_PCT=$(echo $N_NRAF_CUT | awk '{print $1*100}')
T_NRAF_PCT=$(echo $T_NRAF_CUT | awk '{print $1*100}')

$SDIR/mkMAF.sh ${SBASE}_UGT_SNP_AnnoteQDP.vcf \
    $SAMPLE_NORMAL $SAMPLE_TUMOR \
    $N_COV_CUT $T_COV_CUT $N_NRAF_CUT $T_NRAF_CUT \
    | $SDIR/pA_HAJAVA_FILTER_C.py \
    >${SBASE}_UGT_SNP_FILTER_C___MAF.csv

QTAG=qq_15_SPLIT_$OBASE
QRUN 6 \
/opt/bin/java7 -Xmx16g -Djava.io.tmpdir=/scratch/socci \
	-jar /opt/common/gatk/GenomeAnalysisTK-2.6-3-gdee51c4/GenomeAnalysisTK.jar \
	-T SplitSamFile -R $GENOME_FASTQ \
	--outputRoot ${OBASE}_Realign,Recal____ \
	-I ${OBASE}_Realign,Recal.bam
SYNC

QTAG=qq_16_INDEX_$OBASE
for file in ${OBASE}_Realign,Recal____*bam; do
    QRUN 6 \
    $PICARD BuildBamIndex I=$file
done
SYNC

QTAG=qq_17_MUTECT_$OBASE
QRUN 3 \
/opt/bin/java6 -Xmx4g -Djava.io.tmpdir=/scratch/socci -jar $SDIR/bin/muTect-1.1.4.jar \
    --analysis_type MuTect \
    --read_filter BadCigar \
    --reference_sequence $GENOME_FASTQ \
    --dbsnp $DBSNP_VCF \
    --intervals $TARGET_REGION \
    --input_file:normal ${OBASE}_Realign,Recal____${SAMPLE_NORMAL}.bam \
    --input_file:tumor  ${OBASE}_Realign,Recal____${SAMPLE_TUMOR}.bam \
    --coverage_file $OBASE/coverageWig___${CHR}.txt \
    --enable_extended_output \
    -tdf $OBASE/coverageTumor___${CHR}.txt \
    -ndf $OBASE/coverageNormal___${CHR}.txt \
    --vcf $OBASE/mutect___${CHR}.vcf \
    --out ${OBASE}__mutect___${CHR}.out

