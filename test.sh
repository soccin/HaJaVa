./processSamp.sh K16739-Lung ../,testData/LID46442___MERGE___R1.fastq.gz ../,testData/LID46442___MERGE___R2.fastq.gz
./processSamp.sh K16739-T1 ../,testData/LID46443___MERGE___R1.fastq.gz ../,testData/LID46443___MERGE___R2.fastq.gz

./callPairs.sh out/K16739-Lung/K16739-Lung__RG,MD,QFlt30.bam out/K16739-T1/K16739-T1__RG,MD,QFlt30.bam