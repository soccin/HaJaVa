#!/bin/bash
if [ -f ~/.bashrc ] ; then
        . ~/.bashrc
fi
SDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ -z "$HJV_ROOT" ]; then
    echo "You need to set the environment variable HJV_ROOT"
    echo "Please read installation instructions"
    exit
fi


SAMPLE_NORMAL=$1
SAMPLE_TUMOR=$2

#NORMAL=results/$SAMPLE_NORMAL/out/${SAMPLE_NORMAL}___MERGE,MD.bam
#TUMOR=results/$SAMPLE_TUMOR/out/${SAMPLE_TUMOR}___MERGE,MD.bam

if [ ! -f $NORMAL ]; then
	echo NORMAL BAM DOES NOT EXISTS [$NORMAL]
	exit 1
fi
if [ ! -f $TUMOR ]; then
	echo TUMOR BAM DOES NOT EXISTS [$TUMOR]
	exit 1
fi

echo "------------------------------------------------------------------"
echo "callPairsMutect"
echo "NORMAL, TUMOR=" $NORMAL, $TUMOR
echo SAMPLE_NORMAL=$SAMPLE_NORMAL
echo SAMPLE_TUMOR=$SAMPLE_TUMOR
echo

OBASE=${SAMPLE_NORMAL}____${SAMPLE_TUMOR}
echo "OBASE=" $OBASE
mkdir -p $OBASE


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

TARGET_REGION=$SDIR/data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE_SRTChr.bed
KNOWN_SNPS=$SDIR/data/UCSC_dbSNP128_MM9__SRTChr.bed.gz

source $SDIR/bin/sge.sh

QUEUES=lau.q,mad.q,nce.q

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
    --coverage_file $OBASE/coverageWig.txt \
    --enable_extended_output \
    -tdf $OBASE/coverageTumor.txt \
    -ndf $OBASE/coverageNormal.txt \
    --vcf $OBASE/mutect.vcf \
    --out ${OBASE}__mutect.out


