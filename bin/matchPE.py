#!/opt/bin/python2.7

import sys
import gzip

def fastqStream(fname):
    with open(fname) as fp:
        out=[]
        for line in fp:
            out.append(line.strip())
            if len(out)==4:
                yield out
                out=[]

def getID(x,splitChar):
    return x[0].split(splitChar)[0]

outFP=[
    open(sys.argv[3],"w"),
    open(sys.argv[4],"w")
]

cache={}

print >>sys.stderr, "Caching Reads1 ...",

read1Stream=fastqStream(sys.argv[1])
rec=read1Stream.next()

if rec[0].find(" ")>-1:
    print "CASAVA 1.8"
    idSplit=" "
elif rec[0].find("#")>-1:
    print "CASAVA 1.7"
    idSplit="#"
else:
    print >>sys.stderr, "Unknown Hiseq format"
    print >>sys.stderr, "\n".join(rec)

cache[getID(rec,idSplit)]=rec

for rec in read1Stream:
    cache[getID(rec,idSplit)]=rec

print >>sys.stderr, "done caching ... Pairing ...",

for rec in fastqStream(sys.argv[2]):
    if getID(rec,idSplit) in cache:
        print >>outFP[0], "\n".join(cache[getID(rec,idSplit)])
        print >>outFP[1], "\n".join(rec)

print >>sys.stderr, "Finished"

outFP[0].close()
outFP[1].close()

