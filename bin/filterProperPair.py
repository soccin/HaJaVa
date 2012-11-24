#!/usr/bin/env python2.7

import sys

'''
0 QNAME 1  FLAG  2 RNAME
3 POS   4  MAPQ  5 CIGAR
6 RNEXT 7  PNEXT 8 TLEN
9 SEQ   10 QUAL
'''

def bit(flag, bitNo):
    return (flag & (2 ** (bitNo-1))!=0)

for line in sys.stdin:
    if line.startswith("@"):
        print line,
    else:
        F=line.strip().split("\t")
        flag=int(F[1])
        tlen=int(F[8])
        if not bit(flag,3) and not bit(flag,4) \
            and bit(flag,5) != bit(flag,6) \
            and abs(tlen)>80 and abs(tlen)<500:
            print line,