./processSamp.sh LID46443 K16739-T1 >LID46443.log 2>&1 &
echo "FIRST SET SUBMITTED"
sleep 30
./processSamp.sh LID46442 K16739-Lung >LID46442.log 2>&1

echo "starting hold"
qstat
qstat | fgrep socci | awk '{print $1}' | tr '\n' ',' | sed 's/,$//' | xargs -I % bsub -hold_jid % echo "HOLDING"
~/Work/SGE/qSYNC echo
qstat
echo "hold done"

./callPairs.sh out/LID46442___K16739-Lung___RG,Merge,MD,QFlt30.bam out/LID46443___K16739-T1___RG,Merge,MD,QFlt30.bam 
