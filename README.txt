HaJaVa Variant Calling Pipeline
===============================

Pipeline for calling variants using using the following tools

	* BWA [ver  0.5.9-r16]
	* picard [picard-tools-1.55]
	* samtools [0.1.18 (r982:295)]
	* GATK [GenomeAnalysisTK-1.6-7-g2be5704]
	* pysam [pysam.__version__ == '0.6']
    * pyvcf ['0.4.3']

CONFIGURATION
-------------

The files

	bin/paths.sh
	data/dataPaths.sh


needs to be modified to point the the various execuables, JAR files, and temp/scratch directories. More info in the comments of that file. No other edits should be necessary to run.

USAGE
-----

The top level script is:

	./processPair.sh N_Name N_R1 N_R2 T_Name T_R1 T_R2

It takes 6 arguments:

	N_Name = Name of normal sample (no spaces; should be a valid variable name)
	N_R1 = Path to gzip compressed file for R1 reads for normal sample
	N_R2 = Path to gzip compressed file for R2 reads for normal sample
	T_Name = Name of tumor sample (no spaces; should be a valid variable name)
	T_R1 = Path to gzip compressed file for R1 reads for tumor sample
	T_R2 = Path to gzip compressed file for R2 reads for tumor sample

There is a sample dataset included in a separate TAR file. The script

	runTest.sh

will run a test with this test data. Simple edit the DATADIR variable at the top to point to the test dataset.

