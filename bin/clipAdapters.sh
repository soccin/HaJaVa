#!/bin/bash

source bin/sge.sh

FASTQ1=$1
FASTQ2=$2
OUT1=$3
OUT2=$4
ADAPTER_1=$5
ADAPTER_2=$6

TAG=CLIPA_$$_$(hostname|sed 's/.cbio.*//')
echo "----------------------------------------------------"
echo "#clipAdapters.sh"
echo TAG=$TAG
echo $FASTQ1 $FASTQ2
echo $OUT1 $OUT2
echo $ADAPTER_1
echo $ADAPTER_2

#
# The tr '#' ' ' allows the script to work with
# both casava 1.7 and casava 1.8 fastq files
#   casava 1.7 ==> xxxx:xxxx:xxxx#ACGTA/1
#   casava 1.8 ==> xxxx:xxxx:xxxx 1:N:1
#
qsub -pe alloc 2 -N $TAG $QCMD \
  zcat $FASTQ1 \| head -160000 \| fastx_clipper -Q33 -v -n -a $ADAPTER_1 -o ${OUT1}__TMP.fastq \> ${OUT1}__CLIP.log
qsub -pe alloc 2 -N $TAG $QCMD \
  zcat $FASTQ2 \| head -160000 \| fastx_clipper -Q33 -v -n -a $ADAPTER_2 -o ${OUT2}__TMP.fastq \> ${OUT2}__CLIP.log
$QSYNC $TAG
echo "Done with clipping...rePairing..."
bin/matchPE.py ${OUT1}__TMP.fastq ${OUT2}__TMP.fastq ${OUT1} ${OUT2}

TAG=$(head -1 ${OUT1} | awk -F: '{print "^"$1}')

cat ${OUT1} | egrep $TAG | awk -F" |#" '{print $1}' | md5sum >${OUT1}.MD5 &
cat ${OUT2} | egrep $TAG | awk -F" |#" '{print $1}' | md5sum >${OUT2}.MD5 &

rm ${OUT1}__TMP.fastq ${OUT2}__TMP.fastq
