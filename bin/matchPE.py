#!/usr/bin/env python2.7

import sys
import gzip

def fastqStream(fname):
    with gzip.open(fname) as fp:
        out=[]
        for line in fp:
            out.append(line.strip())
            if len(out)==4:
                yield out
                out=[]

def getID(x):
    return x[0].split(" ")[0]

def flip(x):
    return (x+1) % 2

fastq=[
    fastqStream(sys.argv[1]),
    fastqStream(sys.argv[2])
]

outFP=[
    gzip.open(sys.argv[3],"w"),
    gzip.open(sys.argv[4],"w")
]

cache=[[],[]]
index=[{},{}]

i=0
while 1:
    try:
        seq=fastq[i].next()
    except StopIteration:
        break
    if getID(seq) in index[flip(i)]:
        for k in xrange(len(cache[flip(i)])):
            del index[flip(i)][getID(cache[flip(i)][k])]
            if getID(seq)==getID(cache[flip(i)][k]):
                if i==0:
                    print >>outFP[0], "\n".join(seq)
                    print >>outFP[1], "\n".join(cache[flip(i)][k])
                else:
                    print >>outFP[0], "\n".join(cache[flip(i)][k])
                    print >>outFP[1], "\n".join(seq)
                break

        cache[flip(i)]=cache[flip(i)][(k+1):]
        cache[i]=[]
        index[i]={}
    else:
        cache[i].append(seq)
        index[i][getID(seq)]=len(cache[i])
    i=flip(i)

[x.close() for x in outFP]
