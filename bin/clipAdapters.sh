#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )"

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

gzcat $FASTQ1 | $HJV_ROOT/bin/fastx_clipper -Q33 -v -n -a $ADAPTER_1 -o ${OUT1}__TMP.fastq > ${OUT1}__CLIP.log
gzcat $FASTQ2 | $HJV_ROOT/bin/fastx_clipper -Q33 -v -n -a $ADAPTER_2 -o ${OUT2}__TMP.fastq > ${OUT2}__CLIP.log

echo "Done with clipping...rePairing..."
$SDIR/matchPE.py ${OUT1}__TMP.fastq ${OUT2}__TMP.fastq ${OUT1} ${OUT2}

#
# Check the files are paired correctly
#
RUNID=$(head -1 ${OUT1} | awk -F: '{print "^"$1}')
cat ${OUT1} | egrep $RUNID | awk -F" |#" '{print $1}' | md5sum >${OUT1}.MD5 &
cat ${OUT2} | egrep $RUNID | awk -F" |#" '{print $1}' | md5sum >${OUT2}.MD5 &

rm ${OUT1}__TMP.fastq ${OUT2}__TMP.fastq
