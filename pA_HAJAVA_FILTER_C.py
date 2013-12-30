#!/usr/bin/env python2.7

import csv
import sys

class Struct:
    def __init__(self, **entries):
        self.__flds=entries.keys()
        self.__dict__.update(entries)
    def __str__(self):
      return ";".join(map(str,[(x,self.__dict__[x]) for x in self.__flds]))
"""
FILTER SNPEFF_EFFECT SNPEFF_FUNCTIONAL_CLASS SNPEFF_IMPACT
"""

DELTA_NRAF=0.10

DELIMITER=","

cin=csv.DictReader(sys.stdin,delimiter=DELIMITER)
cout=csv.DictWriter(sys.stdout,cin.fieldnames,delimiter=DELIMITER)
cout.writeheader()
for recDict in cin:
  try:
    rec=Struct(**recDict)
    if rec.Mutation_Status!="Somatic":
      continue
    if rec.HaJaVa_FILTER.find("STRAND_FAIL")>-1 or rec.HaJaVa_FILTER.find("NotCovered")>-1:
      continue
    if rec.HaJaVa_FILTER.find("N_NRAF_FAIL")>-1:
      continue
    if 2*float(rec.Normal_Var_Freq)>=float(rec.Tumor_Var_Freq):
      continue        
    cout.writerow(recDict)
  except:
    print recDict
    print
    print
    raise
