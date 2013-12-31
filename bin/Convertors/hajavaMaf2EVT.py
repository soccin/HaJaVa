#!/usr/bin/env python2.7

import sys
import csv

from MutationEvent import *

if len(sys.argv)>1:
    fp=open(sys.argv[1])
else:
    fp=sys.stdin

hajava2call={'???':"UNKNOWN",'Germline':"GERMLINE",
             'Somatic':"SOMATIC",'Unknown':"UNKNOWN"}


MutationEvent.writeHeader(sys.stdout)
cin=csv.DictReader(fp, delimiter=",")
for recDict in cin:
    rec=Struct(**recDict)

    event=MutationEvent()
    event.CHROM=rec.Chromosome
    event.POS=rec.Start_position
    event.REF=rec.Ref
    event.ALT=rec.Var
    event.TUMOR=rec.Tumor_Sample
    event.BASE=rec.Normal_Sample
    event.METHOD="HaJaVa_12_C"

    event.CALL=hajava2call[rec.Mutation_Status]
    event.COVERED = "NOT_COVERED" if rec.HaJaVa_FILTER=="NotCovered" else "COVERED"
    event.FLAG = rec.HaJaVa_FILTER
    event.SCORE = ""

    event.T_NRAF = rec.Tumor_Var_Freq
    event.T_DP = rec.Tumor_Depth
    event.T_RDP = rec.Tumor_Ref_Coverage
    event.T_ADP = rec.Tumor_Alt_Coverage

    event.N_NRAF = rec.Normal_Var_Freq
    event.N_DP = rec.Normal_Depth
    event.N_RDP = rec.Normal_Ref_Coverage
    event.N_ADP = rec.Normal_Alt_Coverage

    event.write(sys.stdout)


"""
Tumor_Sample,Normal_Sample,Tumor_Library,Normal_Library,Gene,
Genic_Location,Mutation_Status,HaJaVa_FILTER,Exon,Variant_Classification,AAChange,
Chromosome,Start_position,Ref,Var,
Normal_Depth,Normal_Ref_Coverage,Normal_Alt_Coverage,
Normal_Alt_Cov_Pos,Normal_Alt_Cov_Neg,
Normal_Var_Freq,Normal_GT,
Tumor_Depth,Tumor_Ref_Coverage,Tumor_Alt_Coverage,
Tumor_Alt_Cov_Pos,Tumor_Alt_Cov_Neg,Tumor_Var_Freq,
Tumor_GT,GATK_FILTER,GATK_QUAL,pValue_Normal_gt,
pValue_Tumor_gt,dbSNP_RS,
HaJaVa_SNP,Refseq_mRNA,Refseq_Protein_ID,
AAChange,Gene_Description,Cyto_Band,
SIFT,Polyphen_2,Mutation_Assesor,GO_Annote,COSMIC_SameLoc,
COSMIC_AALoc,COMIC_NumMutations,COSMIC_AllMutationsInGene
"""
