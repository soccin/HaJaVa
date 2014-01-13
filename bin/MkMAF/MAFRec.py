FIELDS="""
Tumor_Sample    Normal_Sample   Tumor_Library   Normal_Library  Gene
Genic_Location  Mutation_Status HaJaVa_FILTER Exon    Variant_Classification AAChange    Chromosome
Start_position  Ref Var
Normal_Depth Normal_Ref_Coverage Normal_Alt_Coverage
Normal_Alt_Cov_Pos
Normal_Alt_Cov_Neg
Normal_Var_Freq Normal_GT
Tumor_Depth Tumor_Ref_Coverage  Tumor_Alt_Coverage
Tumor_Alt_Cov_Pos
Tumor_Alt_Cov_Neg
Tumor_Var_Freq
Tumor_GT    GATK_FILTER GATK_QUAL   pValue_Normal_gt    pValue_Tumor_gt
dbSNP_RS    HaJaVa_SNP  Refseq_mRNA Refseq_Protein_ID
Gene_Description    Cyto_Band   SIFT    Polyphen_2
Mutation_Assesor    GO_Annote   COSMIC_SameLoc  COSMIC_AALoc    COMIC_NumMutations
COSMIC_AllMutationsInGene
""".strip().split()

DELIMITER=","

class MAFRec(object):
    __slots__=FIELDS
    @classmethod
    def fields(cls):
        return DELIMITER.join(FIELDS)
    def __init__(self):
        for fi in FIELDS:
            setattr(self,fi,".")
    def __repr__(self):
        out=[]
        for fi in FIELDS:
            out.append(str(getattr(self,fi)).replace(DELIMITER,";"))
        return DELIMITER.join(out)
    def format(self,FLDS):
        out=[]
        for fi in FLDS:
            out.append(str(getattr(self,fi)).replace(DELIMITER,";"))
        return DELIMITER.join(out)













