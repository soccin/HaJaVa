#!/bin/bash

source bin/paths.sh
source data/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "

BAM=$1
OBASE=$(basename $BAM | sed 's/_Realign.*//')
echo $OBASE

TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE.bed

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

