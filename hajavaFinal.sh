#!/bin/bash
if [ -f ~/.bashrc ] ; then
        . ~/.bashrc
fi
SDIR="$( cd "$( dirname "$0" )" && pwd )"

source $SDIR/bin/paths.sh
source $SDIR/data/dataPaths.sh
source $SDIR/bin/defs.sh
source $SDIR/bin/sge.sh

TARGET_REGION=$SDIR/data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE_SRTChr.bed
KNOWN_SNPS=$SDIR/data/UCSC_dbSNP128_MM9__SRTChr.bed.gz

if [ -z "$HJV_ROOT" ]; then
    echo "You need to set the environment variable HJV_ROOT"
    echo "Please read installation instructions"
    exit
fi

UGTVCF=$1
SBASE=${UGTVCF/_UGT_SNP_AnnoteQDP.vcf/}

MBQ=17
STAND_CALL_CONF=30
CALLTAG=___MBQ_${MBQ}__CCONF_${STAND_CALL_CONF}

OBASE=${SBASE/$CALLTAG/}
mkdir -p $OBASE

SAMPLE_NORMAL=${OBASE%%____*}
SAMPLE_TUMOR=${OBASE##*____}

echo $SAMPLE_NORMAL, $SAMPLE_TUMOR

echo $OBASE
echo $SBASE


N_COV_CUT=8
T_COV_CUT=14
N_NRAF_CUT=0.05
T_NRAF_CUT=0.15

$SDIR/bin/mkMAF.sh ${SBASE}_UGT_SNP_AnnoteQDP.vcf \
    $SAMPLE_NORMAL $SAMPLE_TUMOR \
    $N_COV_CUT $T_COV_CUT $N_NRAF_CUT $T_NRAF_CUT \
    | $SDIR/pA_HAJAVA_FILTER_C.py \
    >${SBASE}_UGT_SNP_FILTER_C___MAF.csv

echo "Done with HJV_C"
BEDTOOLS=/home/socci/bin/BED/bedtools

$SDIR/bin/Convertors/mutect2EVT.py ${OBASE}__mutect.out \
    | fgrep -v REJECT | fgrep -v NOT_COVERED \
    | $SDIR/bin/Convertors/evt2bed.py \
    | $BEDTOOLS sort -i - \
    | $BEDTOOLS intersect -a - -b $TARGET_REGION -wa \
    | $SDIR/bin/Convertors/bed2evt.sh \
    > ${OBASE}__mutect__KEEP_COVERED_TARGETED___events.txt
echo "Done with MUTECT2EVT"

$SDIR/bin/Convertors/hajavaMaf2EVT.py ${SBASE}_UGT_SNP_FILTER_C___MAF.csv \
    | $SDIR/bin/Convertors/evt2bed.py \
    | $BEDTOOLS sort -i - \
    | $BEDTOOLS intersect -a - -b $TARGET_REGION -wa \
    | $SDIR/bin/Convertors/bed2evt.sh \
    > ${SBASE}_UGT_SNP_FILTER_C___events.txt
echo "Done with HJV2EVT"

$SDIR/bin/joinEvtTables.py \
    ${OBASE}__mutect__KEEP_COVERED_TARGETED___events.txt \
    ${SBASE}_UGT_SNP_FILTER_C___events.txt \
    >${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION.txt


ANNOTATOR=/home/socci/Work/Varmus/PolitiK/Pipeline/ver13/Annotation

#$ANNOTATOR/addAnnotation.py \
#    < ${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION.txt \
#    > ${OBASE}_ANNOTE.txt 2> ${OBASE}_MISSING.txt
#$ANNOTATOR/doAnnovar.sh ${OBASE}_MISSING.txt
#$ANNOTATOR/loadAnnovarGeneAnno.py ${OBASE}_MISSING.txt

$ANNOTATOR/addAnnotation.py \
    < ${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION.txt \
    2> ${OBASE}_MISSING.txt \
    > ${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION__ANNOTE.txt

NORMALDB=/home/socci/Work/Varmus/PolitiK/Pipeline/ver13/NormalEventsMask/normalEventMask__ver13

cat ${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION__ANNOTE.txt \
    | fgrep -vf $NORMALDB \
    > ${SBASE}_UGT_SNP_FILTER_C____MuTect__UNION__ANNOTE__MinusNormals.txt
