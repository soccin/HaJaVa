# Installation #

## 0) Prerequisites

### Standard UNIX software used

This list is probably not complete but if you do not already have most of this stuff installed getting the pipeline to work may be significantly more difficult. *N.B.* for mac users you need to install the developer tools to get the C compiler and associated build tools

* C/C++ compiler [tested with gcc version 4.2.1]
* make [tested with GNU Make 3.81]

* PERL 5 [tested with revision 5.12.4]
* PYTHON 2.7 [tested with 2.7.2]
* java [tested with version 1.6.0_x]

* bash [tested with 3.2.48]
* awk [tested with version 20070501]
* sed

* gzcat [tested with 1.3.5]

Make sure all of these programs are installed and on the default path. In particular all the scripts use the 

	#!/usr/bin/env <PROGRAM> 

convention to specify paths to programs. If this does not work on your system you will have to hand edit the first line of all the scripts to point to the necessary programs.

### Inventory of software to be installed

The following tools need to be installed however this help guide will walk to through installing them. If you already have the appropriate version installed you can just link to them from the bin directory specific in the next step. 

If you do not have them or if you have different version then specified here this guide will show you how to set up local version that will not conflict with the versions you already have

* bwa version 0.5.9-r16
* samtools version 0.1.18 (r982:295)
* fastx_clipper from FASTX Toolkit 0.0.13.2 [0.0.13 will not compile on the OSX]
* picard version 1.55
* GATK version ??

You will also need the following python libraries/modules.

* pysam
* PyVCF

## 1) Create a working directory ##

While not strictly necessary all of the default paths have been set to start at the BASH environment variable

	$HJV_ROOT 

which you need to set and create if you wish the pipeline to work with a minimum of fuss. Also if you want to use the same version of the software we have but not overwrite local version already installed; creating and installing everything in this $HJV_ROOT directory will make that possible

What you actually do will vary but what I did was

	cd ~
	mkdir -p Work/HaJaVa
	cd Work/HaJaVa
	export HJV_ROOT=~/Work/HaJaVa

it would probably be a good idea to find out what the full path is (pwd) and create an alias to set this variable or put this in your .bashrc/.profile

	export HJV_ROOT=~/Work/HaJaVa

Additionally create the following directories where programs and data will go

	mkdir -p $HJV_ROOT/bin
	mkdir -p $HJV_ROOT/data
	mkdir -p $HJV_ROOT/data/mm9

## 2) Get Genome ##

### Already have MM9 downloaded

If you already have the mouse (mm9) genome loaded skim the following section to verify you have the same version. Then there are two options to specify the location of the FASTA file:

1. Make a symlink to it from $HJV_ROOT/data/mm9/mm9.fa

2. Set the environment specified in the configuration of the script explained in section [[??]]

### Getting a copy of the mouse genome

We used mm9 from UCSC. It will take a while to download so start the download right now and continue with other steps while it is downloading in the background.

Read the directions on this page [http://hgdownload.soe.ucsc.edu/goldenPath/mm9/bigZips/]

Put the genome in the directory created in step (1)

	cd $HJV_ROOT/data/mm9

If you have RSYNC installed:

	rsync -avzP \
	  rsync://hgdownload.cse.ucsc.edu/goldenPath/mm9/bigZips/chromFa.tar.gz \
	  .

If not you can use one of the other programs suggested on the directions page	

Unpack tar file and create a single FASTA with all chromosomes in _natural_ order. Not necessary but this is how our genome is.

	tar xvfz chromFa.tar.gz
	cat chr1.fa chr2.fa chr3.fa chr4.fa chr5.fa \
	    chr6.fa chr7.fa chr8.fa chr9.fa chr10.fa \
	    chr11.fa chr12.fa chr13.fa chr14.fa chr15.fa \
	    chr16.fa chr17.fa chr18.fa chr19.fa \
	    chrX.fa chrY.fa chrM.fa chr1_random.fa \
	    chr3_random.fa chr4_random.fa chr5_random.fa \
	    chr7_random.fa chr8_random.fa chr9_random.fa \
	    chr13_random.fa chr16_random.fa chr17_random.fa \
	    chrX_random.fa chrY_random.fa chrUn_random.fa \
	    > mm9.fa

Once you have made the full fasta file you can delete the original tar file (chromFa.tar.gz) and the individual chr*.fa files. 

*N.B.* if you already have samtools installed build the genome fasta index file (*.fai), using the 

	samtools faidx mm9.fa

command. If you do not have samtools installed continue on. Section 5 will describe how to get and install samtools and prompt you to build the index then.

## 3) Install BWA

The version of BWA we used was 

	URL:		http://sourceforge.net/projects/bio-bwa/files/
	File:		bwa-0.5.9.tar.bz2
	Version:	0.5.9-r16

Later versions of the program may work but have not been tested. If you already have a it installed then you should make a symbolic link to it from the $HJV_ROOT/bin dir

	ln -s <PATH/TO/BWA> $HJV_ROOT/bin

If you do not have BWA installed already, download and unpack the tar file; run make and copy the bwa executable to the bin directory using something like the following

	tar xvfj bwa-0.5.9.tar.bz2 
	cd bwa-0.5.9
	make
	cp bwa $HJV_ROOT/bin

## 4) Build Genome Index

To build the BWA index for mouse (mm9) do the following

	cd $HJV_ROOT/data/mm9
	$HJV_ROOT/bin/bwa index -a bwtsw mm9.fa 

This will take some time so you can move on the the next steps while the index is being built. 

If you already have the index built you can either link to the files from the $HJV_ROOT/data/mm9 folder or perhaps easier there is a variable you can set in the pipeline which will be explained later. 

## 5) Install samtools

Version of samtools used:

	Version: 0.1.18 (r982:295)

Again there are two options

1. If you already have samtools installed then make a symlink to it from the $HJV_ROOT/bin dir
	
		ln -s <PATH/TO/samtools> $HJV_ROOT/bin

2. If you do not have samtools then get a copy, building it and then either move the samtools binary to $HJV_ROOT/bin or link to it. 

The code for samtools is available at:

	URL:	http://samtools.sourceforge.net/

### Build genome fasta index file (*.fai) 

Now that you have samtools installed you need to build a genome fasta index file which is used by GATK. Do the following:

	cd $HJV_ROOT/data/mm9
	$HJV_ROOT/bin/samtools faidx mm9.fa

## 6) fastx_clipper from FASTX toolkit

There are many ways to install the FASTX toolkit. All that is needed for the pipeline to run is that either the fastx_clipper binary or a symlink to it is in the $HJV_ROOT/bin directory. 

If you want to install a local copy of it then you can do the following. First you will need to get

	fastx_toolkit-0.0.13.2.tar.bz2
	libgtextutils-0.6.1.tar.bz2

from

	http://hannonlab.cshl.edu/fastx_toolkit/download.html

Note, 0.0.13 will _not_ compile on OSX you need to use 0.0.13.2

Follow the build directions but before you run the

	./configure

command specify set the following environment variables

	export GTEXTUTILS_CFLAGS="-I $HJV_ROOT/include/gtextutils"
	export GTEXTUTILS_LIBS="$HJV_ROOT/lib/libgtextutils.a"

and then use an explicit prefix argument to configure

	./configure --prefix=$HJV_ROOT

which will place the binaries and libraries in the local directory you have created and not in /usr/local or /usr. 

Also you need not do the make install which will install all the FASTX toolkit programs; you can just copy (or link to)

	fastx_toolkit-0.0.13.2/src/fastx_clipper/fastx_clipper

## 7) PICARD tools

_N.B._ both Picard and GATK need a current version of java (1.6.x) to run. Since there is often multiple version of java installed the pipeline script has an explicit variable which needs to be set to the path of the correct java executable. The instructions for this are in the following section. 

We need to install the Picard tools ver 1.55. Again other version may work but the pipeline we ran used this version. Download the JAR files from:

	http://sourceforge.net/projects/picard/files/picard-tools/1.55/

Then change to the $HJV_ROOT/bin directory and unzip the picard ZIP file

	cd $HJV_ROOT/bin
	unzip PATH_TO_PICARD_ZIP_FILE/picard-tools-1.55.zip 

## 8) Install GATK

The version used was: GenomeAnalysisTK-1.6-7-g2be5704

*N.B.* getting this exact version may be difficult or impossible due to policy decisions made at the broad. If you have trouble getting a copy please contact us and we can assist in obtaining a copy.

Place the JAR file in

	$HJV_ROOT/bin/GenomeAnalysisTK-1.6-7-g2be5704/GenomeAnalysisTK.jar

## 9) Install pysam

Explain local installation option and how to set PYTHONLIB variable

## 10) PyVCF

Just figure out how to distribute it with package

## ?) Get pipeline scripts from BitBucket

You can retrive the pipeline scripts from the BitBucket repository by cloning it using Mercurial (hg)
If you do not have hg installed you can get a copy at

	http://mercurial.selenic.com/

Follow the directions to install. Once hg is installed you get the scripts by doing

	cd $HJV_ROOT
	hg clone https://bitbucket.org/soccin/hajava

You can also get a test dataset at:

	http://cbio.mskcc.org/public/SocciN/HaJaVa/PipelineFreeze/testData.tar
	http://cbio.mskcc.org/public/SocciN/HaJaVa/PipelineFreeze/testData.tar.MD5

Create a directory for testing

	mkdir $HJV_ROOT/test
	cd $HJV_ROOT/test

Put the test data tar file here and unpack it. You can delete the tar file after you are finished

	tar xvf http://cbio.mskcc.org/public/SocciN/HaJaVa/PipelineFreeze/testData.tar


## ?+1) Set user paths

### bin/path.sh

1. Set JAVA variable to java program, make sure to also set TMPDIR and size of virtual machine (-Xmx). Note for processing a full or half lane worth of HiSeq data you will need to have a fair amount of RAM. We have used 32Gb in our full scale running of the data sets. You probably only need 4Gb to run the test set. 
2. 