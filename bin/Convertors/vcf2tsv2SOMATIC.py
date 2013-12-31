#!/usr/bin/env python2.7

import sys

def twolines(fp):
    while 1:
        first=fp.next().strip().split("\t")
        second=fp.next().strip().split("\t")
        yield (first,second)

fp=sys.stdin

header=fp.next().strip().split("\t")
pos=header.index("SAMPLE")
newHeader=header[:pos]+["TUMOR"]
newHeader+=["TUM_"+x for x in header[(pos+1):]]
newHeader+=["NORMAL"]+["NOR_"+x for x in header[(pos+1):]]

print "\t".join(newHeader)
for (fi,si) in twolines(fp):
    out=si+fi[(pos):]
    print "\t".join(out)