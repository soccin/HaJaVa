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

$JAVA -jar $GATK -et NO_ET -K socci_cbio.mskcc.org.key \
	-T RealignerTargetCreator \
	-R $GENOME_FASTQ \
	-L $TARGET_REGION -S LENIENT \
	-o ${OBASE}_output.intervals \
	-I $NORMAL -I $TUMOR

exit


if [ -z "DO NOT RUN" ]; then

# Realign

/common/sge/bin/lx24-amd64/qsub -P ngs -N kp_25042012_IR -hold_jid kp_25042012_CHR$c\_RTC -pe alloc 2 /home/mpirun/tools/qCMD /opt/java/jdk1.6.0_16/bin/java -Djava.i
o.tmpdir=/ifs/data/mpirun/temp -jar $GATK -T IndelRealigner -et NO_ET -R /ifs/data/mpirun/genomes/mouse/mm9/kati
e/mm9_KATIE.fasta -L chr$c -S LENIENT -targetIntervals kp_25042012_CHR$c\_output.intervals --maxReadsForRealignment 500000 --maxReadsInMemory 3000000 -o kp_25042012_CHR$c
\_indelRealigned.bam -I s_K1567_Lung/_1/s_K1567_Lung__1_MD.bam -I s_K1567_N1/_1/s_K1567_N1__1_MD.bam -I s_K1576_Lung/_1/s_K1576_Lung__1_MD.bam -I s_K1576_N1/_1/s_K1576_N1
__1_MD.bam -I s_K1688_Lung/_1/s_K1688_Lung__1_MD.bam -I s_K1688_N1/_1/s_K1688_N1__1_MD.bam -I s_K2031_Lung/_1/s_K2031_Lung__1_MD.bam -I s_K2031_N2/_1/s_K2031_N2__1_MD.bam
 -I s_K2348_Lung/_1/s_K2348_Lung__1_MD.bam -I s_K2348_N1/_1/s_K2348_N1__1_MD.bam

# CountCovariates

/common/sge/bin/lx24-amd64/qsub -N KP_Sample_LID46438_46_CC -hold_jid KP_Sample_LID46438_46_MERGE3 -pe alloc 12 /home/mpirun/tools/qCMD /opt/bin/java -Xms256m -Xmx96g -XX:-UseGCOverheadLimit -Djava.io.tmpdir=/ifs/data/mpirun/temp -jar $GATK -T CountCovariates -et NO_ET -l INFO -R $GENOME_FASTQ -L /ifs/data/mpirun/analysis/solexa/varmus/Mouse_Cancer1000/target/110624_MM9_exome_L2R_D02_EZ_HX1.interval_list -S LENIENT -nt 12 -cov ReadGroupCovariate -cov QualityScoreCovariate -cov CycleCovariate -cov DinucCovariate -cov MappingQualityCovariate -cov MinimumNQSCovariate --knownSites:BED /ifs/data/mpirun/data/dbSNP/UCSC_dbSNP128_MM9.bed -recalFile KP_Sample_LID46438_46_indelRealigned.recal_data.csv -I KP_Sample_LID46438_46_indelRealigned.bam

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

