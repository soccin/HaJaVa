#!/bin/bash

source bin/paths.sh
source data/dataPaths.sh

GATK="$JAVA -jar $GATKJAR "
GATK_BIG="$JAVA -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -jar $GATKJAR "
TARGET_REGION=data/110624_MM9_exome_L2R_D02_EZ_HX1___MERGE.bed

BAM=$1
BASE=$(basename $BAM)
BASE=${BASE%%.bam}
echo $BASE

# CountCovariates

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
	--knownSites:BED data/UCSC_dbSNP128_MM9__SRT.bed \
	-I $BAM \
	-recalFile ${BASE}_recal_data.csv

