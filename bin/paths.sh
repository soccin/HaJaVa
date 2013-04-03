##
# Paths
##

############################################################
#
# Path to programs, scripts, JARs, ...
# All of these must be change to the correct path on our system
#

# TMPDIR for scatch space. Do not use /tmp or /var/tmp unless you
# have lots of space there (many Gigabytes). This is used by
# GATK, Picard and also potentially Java
#
TMPDIR=/tmp

# JAVA executable
# !!! Make sure tmpdir is set properly. 
# Also check to make sure to set
#    -Xmx 
# To be less than the total RAM available. 

JAVA="$HJV_ROOT/bin/java -Djava.io.tmpdir=$TMPDIR -Xmx4g"

# BWA executable. We are using Version: 0.5.9-r16
BWA=$HJV_ROOT/bin/bwa

# SAMTOOLS executable. We are using Version: 0.1.18 (r982:295)
SAMTOOLS=$HJV_ROOT/bin/samtools

# Directory of PICARD jars. We are using 1.55
PICARDDIR=$HJV_ROOT/bin/picard-tools-1.55

# The GATK jar. We are using version 1.6-7
GATKJAR=$HJV_ROOT/bin/GenomeAnalysisTK-1.6-7-g2be5704/GenomeAnalysisTK.jar

