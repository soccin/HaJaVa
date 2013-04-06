#!/usr/bin/env python2.7

import sys
from collections import OrderedDict, namedtuple

import pysam
import vcf

qDepthStruct=namedtuple("qDepthStruct","qADREF qADALTF qADALTR")

if len(sys.argv)!=4:
    print "usage: annoteVCF.py VCFIN BAM MBQ"
    sys.exit()

VCFIN=sys.argv[1]
BAM=sys.argv[2]
MBQ=int(sys.argv[3])

sam=pysam.Samfile(BAM,"rb")

def cvtQual(x):
    return ord(x)-33

def strand(x):
    return "-" if x.is_reverse else "+"

def strandIdx(x):
    return 1 if x.is_reverse else 0

baseIdx={"A":0,"C":1,"G":2,"T":3}

def getDepth(sam, chrom, pos, rgMap, mbq, mapq=0):
    """
    getPileup: return pileup counts for a given chrom:pos
    use a baseQ cutoff of mbq (>=mbq) and mapq cutoff of mapq

    Note accumulate the pileup counts by Sample (SM:)
    note by readGroup
    """
    counts=dict([(x,[[0]*4,[0]*4]) for x in rgMap.values()])
    for pileup in sam.pileup(chrom, pos-1, pos):
        if pileup.pos+1==pos:
            for read in pileup.pileups:
                if read.alignment.mapq>mapq and read.alignment.seq[read.qpos].upper()!="N" \
                  and cvtQual(read.alignment.qual[read.qpos])>=mbq:
                    read_RG=dict(read.alignment.tags)['RG']
                    counts[rgMap[read_RG]][strandIdx(read.alignment)][baseIdx[read.alignment.seq[read.qpos]]]+=1
    return counts

def getALTIdx(si):
    if si.called:
        if si.phased:
            idxSet=set(si.data["GT"].split("|"))
        else:
            idxSet=set(si.data["GT"].split("/"))
        return [int(x) for x in idxSet if x !="0"]
    else:
        return None

def computeSampleQDP(sampleCounts):
    return sum([sum(x) for x in sampleCounts])

def computeTotalQDP(pileDepths):
    total_QDP=0
    for depth in pileDepths.values():
        total_QDP+=computeSampleQDP(depth)
    return total_QDP



def computeDepths(sample,pileDepths):
    sampleName=sample.sample
    altIdx=getALTIdx(sample)
    biREF=baseIdx[sample.site.REF]
    AD_REF=pileDepths[sampleName][0][biREF]+pileDepths[sampleName][1][biREF]
    if altIdx and len(altIdx)==1:
        biALT=baseIdx[sample.site.ALT[altIdx[0]-1]]
        AD_ALT=[pileDepths[sampleName][0][biALT],pileDepths[sampleName][1][biALT]]
    elif altIdx:
        AD_ALT=[None,None]
    else:
        AD_ALT=[0,0]
    return qDepthStruct(AD_REF, AD_ALT[0], AD_ALT[1])


programTag="AnnoteVCF"
vheader=vcf.Reader(open(VCFIN))
vheader.metadata[programTag]='"MBQ=%d"' % (MBQ)

vheader.formats["qADREF"]=vcf.parser._Format("qADREF","1","Integer","Exact allele depth (inc BaseQ [mbq] filtering) for Reference")
vheader.formats["qADALTF"]=vcf.parser._Format("qADALTF","1","Integer","Exact allele depth (inc BaseQ [mbq] filtering) for Alternate FORWARD STRAND")
vheader.formats["qADALTR"]=vcf.parser._Format("qADALTR","1","Integer","Exact allele depth (inc BaseQ [mbq] filtering) for Alternate REVERSE STRAND")
vheader.formats["qDP"]=vcf.parser._Format("qDP","1","Integer","Exact read depth (including BaseQ [mbq] filtering)")

keys0=vheader.metadata_id_order.keys()[:-2]
keys1=vheader.metadata_id_order.keys()[-2:]
d=vheader.metadata_id_order
vheader.metadata_id_order=OrderedDict(
    [(x,d[x]) for x in keys0]
    +[(programTag,None)]
    +[(x,d[x]) for x in keys1])

vout=vcf.Writer(sys.stdout,vheader)

vin=vcf.Reader(open(VCFIN))
sampleMap=dict([(x,i) for (i,x) in enumerate(vin.samples)])
readGroupMap=dict([(x['ID'],x['SM']) for x in sam.header['RG']])

for rec in vin:
    #
    # Added new field to FORMAT
    #
    rec.FORMAT+=":qDP:qADREF:qADALTF:qADALTR"
    noCoverage=True
    for pileup in sam.pileup(rec.CHROM,rec.POS-1,rec.POS):
        if pileup.pos+1==rec.POS:
            pileDepths=getDepth(sam,rec.CHROM,rec.POS,readGroupMap,MBQ)
            total_qDP=computeTotalQDP(pileDepths)
            rec.INFO["qDP"]=total_qDP
            for si in rec.samples:
                #
                # Set qDP field for each sample
                #
                si.data["qDP"]=computeSampleQDP(pileDepths[si.sample])
                qAD=computeDepths(si,pileDepths)
                si.data["qADREF"]=qAD.qADREF
                si.data["qADALTF"]=qAD.qADALTF
                si.data["qADALTR"]=qAD.qADALTR
            noCoverage=False
    if noCoverage:
        rec.INFO["qDP"]=total_qDP
        for si in rec.samples:
            si.data["qDP"]=0
            si.data["qADREF"]=0
            si.data["qADALTF"]=0
            si.data["qADALTR"]=0
            si.data["GT"]="./."

    vout.write_record(rec)

