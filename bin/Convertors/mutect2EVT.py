#!/usr/bin/env python2.7

import sys
import csv

from MutationEvent import *

def skipFirstLine(fp):
    fp.readline()
    for line in fp:
        yield line

MutationEvent.writeHeader(sys.stdout)
for muFile in sys.argv[1:]:
    print >>sys.stderr, muFile
    cin=csv.DictReader(skipFirstLine(open(muFile)), delimiter="\t")
    for recDict in cin:
        rec=Struct(**recDict)

        event=MutationEvent()
        event.CHROM=rec.contig
        event.POS=rec.position
        event.REF=rec.ref_allele
        event.ALT=rec.alt_allele
        event.TUMOR=rec.tumor_name
        event.BASE=rec.normal_name
        event.METHOD="muTect_1.4"
        if rec.judgement=="KEEP":
            event.CALL="SOMATIC"
        else:
            event.CALL="NC"
        event.COVERED = "COVERED" if rec.covered=="COVERED" else "NOT_COVERED"
        event.FLAG = rec.judgement
        event.SCORE = rec.score

        tumorDepthRef=float(rec.t_ref_count)
        tumorDepthAlt=float(rec.t_alt_count)
        normalDepthRef=float(rec.n_ref_count)
        normalDepthAlt=float(rec.n_alt_count)

        if (tumorDepthRef) > 0:
            event.T_NRAF = tumorDepthAlt/(tumorDepthRef+tumorDepthAlt)
        else:
            event.T_NRAF = 0

        event.T_DP = tumorDepthRef+tumorDepthAlt
        event.T_RDP = tumorDepthRef
        event.T_ADP = tumorDepthAlt

        if (normalDepthRef) > 0:
            event.N_NRAF = normalDepthAlt/(normalDepthRef+normalDepthAlt)
        else:
            event.N_NRAF = 0
        event.N_DP = normalDepthRef+normalDepthAlt
        event.N_RDP = normalDepthRef
        event.N_ADP = normalDepthAlt

        event.write(sys.stdout)



"""
contig position context ref_allele alt_allele
tumor_name normal_name score dbsnp_site covered
power tumor_power normal_power total_pairs improper_pairs
map_Q0_reads t_lod_fstar tumor_f contaminant_fraction contaminant_lod
t_ref_count t_alt_count t_ref_sum t_alt_sum t_ref_max_mapq
t_alt_max_mapq t_ins_count t_del_count normal_best_gt init_n_lod
n_ref_count n_alt_count n_ref_sum n_alt_sum judgement
"""
"""
CHROM POS REF ALT TUMOR BASE
METHOD CALL FLAG COVERED SCORE
T_NRAF T_DP T_RDP T_ADP
N_NRAF N_DP N_RDP N_ADP
"""



