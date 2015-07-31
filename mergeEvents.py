#!/usr/bin/env python2.7

import sys
import csv

def fixChrom(chrom):
    if chrom[3:].isdigit():
        return int(chrom[3:])
    else:
        return chrom[3:]

def getKey(rec):
    return (fixChrom(rec["CHROM"]),int(rec["POS"]),rec["REF"],rec["ALT"],rec["TUMOR"],rec["BASE"])

events=dict()

for fname in sys.argv[1:]:
    #print >>sys.stderr, fname
    cin=csv.DictReader(open(fname))
    for rec in cin:
        key=getKey(rec)
        events[key]=rec

cout=csv.DictWriter(sys.stdout,cin.fieldnames,delimiter="\t")
cout.writeheader()
for ki in sorted(events.keys()):
    cout.writerow(events[ki])