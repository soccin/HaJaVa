#!/usr/bin/env python2.7

import lib.vcf as vcf
import sys

N_NRAF_CUT=0.05
T_NRAF_CUT=0.15

def getGT(sample):
    gt=sample.data["GT"]
    if gt:
        return gt
    else:
        return './.'

def getDepth(sample):
    return sample.data["qDP"]

def compNRAF(sample):
    if getGT(sample) in ["0/1","1/1"]:
        return (float(sample["qADALTF"])+float(sample["qADALTR"]))/float(sample["qDP"])
    else:
        return (float(sample["qDP"]-sample["qADREF"]))/float(sample["qDP"])

def flatten(s):
    if isinstance(s,list):
        return ",".join(map(str,s))
    else:
        return s

def formatSite(r):
    return "\t".join(map(str,[r.CHROM,r.POS,r.REF,flatten(r.ALT)]))

def formatCall(c):
    return ":".join(map(str,[
        getGT(c),
        getDepth(c),
        "%s/%s|%s" % (str(c.data["qADREF"]),str(c.data["qADALTF"]),str(c.data["qADALTR"]))
        ]))

def roundNA(x,scale):
    if x != "NA":
        return round(x,scale)
    else:
        return "NA"

VCF=sys.argv[1]

vin=vcf.Reader(open(VCF))
if len(sys.argv)==2:
    print "Samples =",  ", ".join(vin.samples)
    sys.exit()

NORMAL_NAME=sys.argv[2]
TUMOR_NAME=sys.argv[3]

for rec in vin:
    normal=rec.genotype(NORMAL_NAME)
    tumor=rec.genotype(TUMOR_NAME)

    normal_NRAF="NA"
    tumor_NRAF="NA"
    event=""

    # qDepth==qual Filtered depth
    # qDepth(normal)>=8 AND qDepth(tumor)>=14
    if getDepth(normal)>=8 and getDepth(tumor)>=14:

        event="Covered"
        normal_NRAF=compNRAF(normal)
        tumor_NRAF=compNRAF(tumor)

        # Both normal and tumor have calls
        # and normal is homozyg REF and turmor is not homozyg REF
        if getGT(normal)=="0/0" and getGT(tumor) not in ["0/0", "./."]:

            event="non-Germ"


            # Check for stand support
            if tumor.data["qADALTF"]>0 and tumor.data["qADALTR"]>0:

                if normal_NRAF<N_NRAF_CUT and tumor_NRAF>T_NRAF_CUT:
                    event="Somatic"
                else:
                    if normal_NRAF>=N_NRAF_CUT:
                        event+=",N_NRAF_FAIL"
                    if tumor_NRAF<=T_NRAF_CUT:
                        event+=",T_NRAF_FAIL"

            else:
                event+=",STRAND_FAIL"

        else:
            # Is it Germline or non-signal
            if getGT(normal)!="./.":
                event="Germline"
            else:
                event="???"
    else:
        event="NotCovered"

    if event=="Somatic":
        call="POS"
    elif event=="NotCovered":
        call="NC"
    else:
        call="NEG"

    print "\t".join(map(str,[
        formatSite(rec), call, event,
        formatCall(normal), roundNA(normal_NRAF, 3),
        formatCall(tumor), roundNA(tumor_NRAF, 3)
        ]))
