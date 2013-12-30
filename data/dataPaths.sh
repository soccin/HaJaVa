##
# Data Paths
##

############################################################
# Genome Paths
#    GENOME_FASTQ must point the FASTA file for the genome
#    GENOME_BWA must point to the BWA index

GDIR=$HJV_ROOT/data/mm9

#WT MOUSE
GENOME_FASTQ=$GDIR/mm9.fa
GENOME_BWA=$GDIR/mm9.fa
DBSNP_VCF=$GDIR/dbsnp128__mm9.vcf.gz
COSMIC_VCF=$GDIR/pseudoCosmic__P0.vcf

#hMYC MOUSE
#GENOME_FASTQ=$GDIR/mouse_mm9__All_hMYC.fa
#GENOME_BWA=$GDIR/BWA/DNA/mouse_mm9__All_hMYC.fa
#hEGFR MOUSE
#GENOME_FASTQ=$GDIR/mouse_mm9__All_hEGFR.fa
#GENOME_BWA=$GDIR/BWA/DNA/mouse_mm9__All_hEGFR.fa

