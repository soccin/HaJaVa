##
# Paths
##


############################################################
# Genome Information

# Convience variables not used explicitly

GENOME_DIR="/ifs/data/bio/Genomes/M.musculus/mm9"
GENOME_TAG=mouse_mm9__FULL_hEGFR

# These two have to be set
#    GENOME_FASTQ must point the FASTA file for the genome
#    GENOME_BWA must point to the BWA index

GENOME_FASTQ=$GENOME_DIR/${GENOME_TAG}.fa
GENOME_BWA=$GENOME_DIR/BWA/DNA/$GENOME_TAG

############################################################
# Path to programs, scripts, JARs, ...

SDIR=$(dirname $0)

TMPDIR=/scratch/socci

JAVA="/opt/java/jdk1.6.0_16/bin/java -Djava.io.tmpdir="$TMPDIR
JAVABIN=$SDIR/bin/java

GATKJAR=bin/java/GenomeAnalysisTK-1.6-7-g2be5704/GenomeAnalysisTK.jar
BWA=/home/socci/bin/bwa
PICARD=bin/picard

############################################################
# SGE stuff

SGE=/home/socci/Work/SGE
