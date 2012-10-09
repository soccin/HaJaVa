#!/bin/bash

source bin/sge.sh

FASTQ1=$1
FASTQ2=$2
OUT1=$3
OUT2=$4
ADAPTER=$5

TAG=CLIPA_$$_$(hostname|sed 's/.cbio.*//')
echo "----------------------------------------------------"
echo "#clipAdapters.sh"
echo TAG=$TAG
echo $FASTQ1 $FASTQ2
echo $OUT1 $OUT2
echo $ADAPTER

#
# The tr '#' ' ' allows the script to work with
# both casava 1.7 and casava 1.8 fastq files
#   casava 1.7 ==> xxxx:xxxx:xxxx#ACGTA/1
#   casava 1.8 ==> xxxx:xxxx:xxxx 1:N:1
#
qsub -pe alloc 3 -N $TAG $QCMD \
  zcat $FASTQ1 \| tr '"#"' '" "' \| fastx_clipper -Q33 -z -v -n -a $ADAPTER -o ${OUT1}__TMP.fastq.gz \> ${OUT1}__CLIP.log
qsub -pe alloc 3 -N $TAG $QCMD \
  zcat $FASTQ2 \| tr '"#"' '" "' \| fastx_clipper -Q33 -z -v -n -a $ADAPTER -o ${OUT2}__TMP.fastq.gz \> ${OUT2}__CLIP.log
$QSYNC $TAG

bin/matchPE.py ${OUT1}__TMP.fastq.gz ${OUT2}__TMP.fastq.gz ${OUT1} ${OUT2}

zcat ${OUT1} | egrep "^@" | awk '{print $1}' | md5sum >${OUT1}.MD5 &
zcat ${OUT2} | egrep "^@" | awk '{print $1}' | md5sum >${OUT2}.MD5 &

rm ${OUT1}__TMP.fastq.gz ${OUT2}__TMP.fastq.gz
