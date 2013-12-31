#!/usr/bin/env python2.7
import sys
header=sys.stdin.readline()
for line in sys.stdin:
    (chrom, pos)=line.strip().split("\t")[:2]
    pos=int(pos)
    info=line.strip().replace("\t",";")
    print "\t".join([chrom, str(pos-1), str(pos), info])