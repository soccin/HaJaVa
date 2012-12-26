#!/bin/bash

ISEMPTY=$(qstat)

if [ -z "$ISEMPTY" ]; then
    echo "1"
else
    qstat -f| fgrep BIP | egrep -v "d$" | fgrep all.q | awk '{print $3}' | awk -F"/" '$2<=4{print $2}' | wc -l
fi