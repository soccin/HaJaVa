import cPickle
import sys
import vcf

from SomaticDetector import *
from MAFRec import MAFRec
from collections import defaultdict

##################################################
def castInt(x):
    if x:
        return x
    else:
        return 0

def protect(x):
    return "'"+str(x)

def getEventTag(rec):
    return ":".join(map(str,(rec.CHROM,rec.POS,rec.POS,rec.REF,rec.ALT[0])))

##################################################

OUTPUT_FLDS="""
Tumor_Sample    Normal_Sample   Tumor_Library   Normal_Library  Gene
Genic_Location  Mutation_Status HaJaVa_FILTER Exon    Variant_Classification AAChange    Chromosome
Start_position  Ref Var Normal_Depth Normal_Ref_Coverage Normal_Alt_Coverage
Normal_Alt_Cov_Pos
Normal_Alt_Cov_Neg
Normal_Var_Freq Normal_GT   Tumor_Depth Tumor_Ref_Coverage  Tumor_Alt_Coverage
Tumor_Alt_Cov_Pos
Tumor_Alt_Cov_Neg
Tumor_Var_Freq
Tumor_GT    GATK_FILTER GATK_QUAL   pValue_Normal_gt    pValue_Tumor_gt
dbSNP_RS    HaJaVa_SNP  Refseq_mRNA Refseq_Protein_ID   AAChange
Gene_Description    Cyto_Band   SIFT    Polyphen_2
Mutation_Assesor    GO_Annote   COSMIC_SameLoc  COSMIC_AALoc    COMIC_NumMutations
COSMIC_AllMutationsInGene
""".strip().split()

#db=cPickle.load(open("annovar.pydict","rb"))
#db=shove.Shove(store="sqlite:///annovar.db")

#import uuid
#UUID=str(uuid.uuid1())
#missing=open("missingEvents_"+UUID+".txt","a+")

print ",".join(OUTPUT_FLDS)

VCFFILE=sys.argv[1]
vin=vcf.Reader(open(VCFFILE))
normalName=sys.argv[2]
tumorName=sys.argv[3]

N_COV_CUT=int(sys.argv[4])
T_COV_CUT=int(sys.argv[5])
N_NRAF_CUT=float(sys.argv[6])
T_NRAF_CUT=float(sys.argv[7])

for rec in vin:
    normal=rec.genotype(normalName)
    tumor=rec.genotype(tumorName)
    (call, event) = callEvent(rec,normalName,tumorName,
                N_COV_CUT=8,N_NRAF_CUT=0.05,
                T_COV_CUT=14,T_NRAF_CUT=0.15)
    try:
        normalNRAF=compNRAF(normal)
        tumorNRAF=compNRAF(tumor)
    except TypeError:
        normalNRAF="NA"
        tumorNRAF="NA"

    mrec=MAFRec()
    mrec.Tumor_Sample=tumorName
    mrec.Normal_Sample=normalName
    mrec.Chromosome=rec.CHROM
    mrec.Start_position=rec.POS
    mrec.Ref=rec.REF
    mrec.Var=";".join(rec.ALT)
    mrec.GATK_FILTER=rec.FILTER if rec.FILTER != "." else "PASS"
    mrec.GATK_QUAL=rec.QUAL
    eventFlags=event.split(",")
    mrec.Mutation_Status=eventFlags[0]
    mrec.HaJaVa_FILTER=",".join(event.split(",")[1:]) if len(eventFlags)>1 else "OK"
    mrec.Normal_GT=protect(normal.data["GT"])
    mrec.Normal_Depth=castInt(normal.data["qDP"])
    mrec.Normal_Ref_Coverage=castInt(normal.data["qADREF"])
    mrec.Normal_Alt_Coverage=castInt(normal.data['qADALTF'])+castInt(normal.data['qADALTR'])
    mrec.Normal_Alt_Cov_Pos=castInt(normal.data['qADALTF'])
    mrec.Normal_Alt_Cov_Neg=castInt(normal.data['qADALTR'])
    mrec.Normal_Var_Freq=normalNRAF

    mrec.Tumor_GT=protect(tumor.data["GT"])
    mrec.Tumor_Depth=castInt(tumor.data["qDP"])
    mrec.Tumor_Ref_Coverage=castInt(tumor.data["qADREF"])
    mrec.Tumor_Alt_Coverage=castInt(tumor.data['qADALTF'])+castInt(tumor.data['qADALTR'])
    mrec.Tumor_Alt_Cov_Pos=castInt(tumor.data['qADALTF'])
    mrec.Tumor_Alt_Cov_Neg=castInt(tumor.data['qADALTR'])
    mrec.Tumor_Var_Freq=tumorNRAF

    # tag=getEventTag(rec)
    # if tag in db:
    #     try:
    #         annovar=defaultdict(lambda: "", [x.split(":") for x in db[tag].split(",")])
    #         mrec.Gene=annovar["Gene"]
    #         mrec.Genic_Location=annovar["Genic_Location"]
    #         mrec.Exon=annovar["Exon"]
    #         mrec.AAChange=annovar["AAChange"]
    #         mrec.dbSNP_RS=annovar["dbSNP_RS"]
    #         mrec.Variant_Classification=annovar["Variant_Classification"]
    #     except:
    #         print >>sys.stderr, tag
    #         print db[tag]
    #         print
    #         raise
    #         sys.exit()
    # else:
    #     print >>missing, tag.replace(":","\t")

    print mrec.format(OUTPUT_FLDS)
