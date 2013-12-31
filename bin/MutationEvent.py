#!/usr/bin/env python2.7

class Struct:
    def __init__(self, **entries):
        self.__dict__.update(entries)

class MutationEvent(object):
    EVT_FIELDS="""
            CHROM POS REF ALT TUMOR BASE
            METHOD CALL FLAG COVERED SCORE
            T_NRAF T_DP T_RDP T_ADP
            N_NRAF N_DP N_RDP N_ADP
            """.strip().split()

    @staticmethod
    def writeHeader(fp, delimiter="\t"):
        print >>fp, delimiter.join(MutationEvent.EVT_FIELDS)

    def __init__(self,recDict=None):
        for evtF in MutationEvent.EVT_FIELDS:
            self.__dict__[evtF]=""
            if recDict:
                self.__dict__.update(recDict)

    def write(self,fp,delimiter="\t"):
        print >>fp, delimiter.join([str(getattr(self, ei)) for ei in MutationEvent.EVT_FIELDS])

    def __str__(self,delimiter=" "):
        return delimiter.join(["%s:%s" % (ei, str(getattr(self, ei))) for ei in MutationEvent.EVT_FIELDS])

    def __repr__(self):
        return self.__str__(";")