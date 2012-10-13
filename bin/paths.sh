##
# Paths
##

############################################################
#
# Path to programs, scripts, JARs, ...
# All of these must be change to the correct path on our system
#

# TMPDIR for scatch space. Do not use /tmp or /var/tmp unless you
# have lots of space there (many Gigabytes). This is used by
# GATK, Picard and also potentiall Java
#
TMPDIR=/scratch/socci

# JAVA executable
# !!! Make sure tmpdir is set properly. 
JAVA="/opt/java/jdk1.6.0_16/bin/java -Djava.io.tmpdir=$TMPDIR"

# The GATK jar. We are using version 1.6-7
GATKJAR=bin/java/GenomeAnalysisTK-1.6-7-g2be5704/GenomeAnalysisTK.jar

# Directory of PICARD jars. We are using 1.55
PICARDDIR=bin/java/picard-tools-1.55

# BWA executable. We are using Version: 0.5.9-r16
BWA=/home/socci/bin/bwa

# SAMTOOLS executable. We are using Version: 0.1.18 (r982:295)
SAMTOOLS=/home/socci/bin/samtools

############################################################
# Genome Paths
#    GENOME_FASTQ must point the FASTA file for the genome
#    GENOME_BWA must point to the BWA index

GENOME_FASTQ=/ifs/data/bio/Genomes/M.musculus/mm9/mouse_mm9__FULL.fa
GENOME_BWA=/ifs/data/bio/Genomes/M.musculus/mm9/BWA/DNA/mouse_mm9__FULL

############################################################
############################################################
############################################################
# Local paths to included software do not change
#
PICARD=bin/picard
JAVABIN=bin/java
