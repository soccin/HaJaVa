#!/bin/bash

COV=$1
BASE=$(basename $COV)
BASE=${BASE%.*}

ACOV="/opt/java/jdk1.6.0_16/bin/java -Djava.io.tmpdir=/scratch/socci -jar /ifs/data/bio/tools/GATK/GenomeAnalysisTK-1.6-13-g91f02df/AnalyzeCovariates.jar "

$ACOV -recalFile $COV -outputDir $BASE


