#!/usr/bin/env python2.7

import sys
import csv
from collections import defaultdict
import gzip

from MutationEvent import *

def fixChrom(chrom):
    x=chrom[3:]
    if x in ["X","Y","M"]:
        return x
    else:
        return int(x)

def smartOpen(fname):
    if fname.endswith(".gz"):
        return gzip.open(fname)
    else:
        return open(fname)

evtFiles=sys.argv[1:]
events=defaultdict(dict)
methods=set()

for fname in evtFiles:
    i=0
    print >>sys.stderr, "Processing", fname
    fp=smartOpen(fname)
    cin=csv.DictReader(fp,delimiter="\t")
    for recDict in cin:
        event=MutationEvent(recDict)
        methods.add(event.METHOD)
        key=(fixChrom(event.CHROM), event.POS, event.REF, event.ALT, event.TUMOR, event.BASE)
        events[key][event.METHOD]=event
        i+=1
        if i>9e99:
            break

print >>sys.stderr, "Done with reading"

DELIMITER=","
header="CHROM POS REF ALT TUMOR BASE".replace(" ",DELIMITER)
detail="CALL FLAG COVERED T_NRAF T_DP T_ADP N_NRAF N_DP N_ADP".split()
for mi in methods:
    mi.replace(".","_")
    header+=DELIMITER+DELIMITER.join([mi+"."+ci for ci in detail])

print header
for evt in sorted(events):
    out = list(evt)
    out[0]="chr"+str(out[0])
    for mi in methods:
        if events[evt].has_key(mi):
            call=events[evt][mi]
            out.append(call.CALL)
            out.append(call.FLAG)
            out.append(call.COVERED)
            out.append(call.T_NRAF)
            out.append(call.T_DP)
            out.append(call.T_ADP)
            out.append(call.N_NRAF)
            out.append(call.N_DP)
            out.append(call.N_ADP)
        else:
            out.extend(["na"]*9)

    print DELIMITER.join(map(str,out))


"""
CHROM POS REF ALT TUMOR
BASE METHOD CALL FLAG COVERED
SCORE T_NRAF T_DP T_RDP T_ADP
N_NRAF N_DP N_RDP N_ADP
"""