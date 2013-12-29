#!/bin/bash
cat qq_*.e* | egrep -v "(INFO|Java HotSpot|Elapsed time:|Runtime.totalMemory|^\[bwa_|^\[infer_|^Caching)" | uniq
