./processSamp.sh LID46443 K16739-T1 >LID46443.log 2>&1 & 
./processSamp.sh LID46442 K16739-Lung >LID46442.log 2>&1 &
./callPairs.sh out/LID46443___K16739-T1___RG,Merge,MD,QFlt30.bam out/LID46442___K16739-Lung___RG,Merge,MD,QFlt30.bam
