#!/bin/bash
qstat -f| fgrep BIP | egrep -v "d$" | fgrep all.q | awk '{print $3}' | awk -F"/" '{print (r+=100*$2)/(s+=$3)}' | tail -1
