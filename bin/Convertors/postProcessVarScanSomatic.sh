#!/bin/bash

VCF=$1
NORMAL=$2
TUMOR=$3

head -5000 $VCF | egrep "^#" | sed 's/##INFO=<ID=DP/##INFO=<ID=TDP/' | sed 's/NORMAL/'$NORMAL'/' | sed 's/TUMOR/'$TUMOR'/'
cat $VCF | egrep -v "^#" | sed 's/DP=/TDP=/' | sed 's/%//g' | fgrep "SS=2" 
