#!/opt/bin/python2.7

import vcf
import sys

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

def callEvent(rec,NORMAL_NAME,TUMOR_NAME,
                N_COV_CUT=8,N_NRAF_CUT=0.05,
                T_COV_CUT=14,T_NRAF_CUT=0.15):

    normal=rec.genotype(NORMAL_NAME)
    tumor=rec.genotype(TUMOR_NAME)

    normal_NRAF="NA"
    tumor_NRAF="NA"
    event=""

    # qDepth==qual Filtered depth
    # qDepth(normal)>=N_COV_CUT AND qDepth(tumor)>=T_COV_CUT
    if getDepth(normal)>=N_COV_CUT and getDepth(tumor)>=T_COV_CUT:

        event="Covered"
        normal_NRAF=compNRAF(normal)
        tumor_NRAF=compNRAF(tumor)

        # Both normal and tumor have calls
        # and normal is homozyg REF and turmor is not homozyg REF
        if getGT(normal)=="0/0" and getGT(tumor) not in ["0/0", "./."]:

            event="Somatic"

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
            if getGT(normal)!="./." and getGT(normal)==getGT(tumor):
                event="Germline"
            else:
                event="???"
    else:
        if getGT(normal)=="0/0" and getGT(tumor) not in ["0/0", "./."]:
            event="Somatic,NotCovered"
        else:
            if getGT(normal)==getGT(tumor) and getGT(normal) not in ["0/0", "./."]:
                event="Germline,NotCovered"
            else:
                event="Unknown,NotCovered"

    if event=="Somatic":
        call="POS"
    elif event=="NotCovered":
        call="NC"
    else:
        call="NEG"

    return (call, event)
