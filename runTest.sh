#!/bin/bash
SDIR="$( cd "$( dirname "$0" )" && pwd )" 

if [ -z "$HJV_ROOT" ]; then
	echo "You need to set the environment variable HJV_ROOT"
	echo "Please read installation instructions"
	exit
fi

$SDIR/processDirPair.sh DM808NT TestData/DM1001_DM808NT_1 DM808T3 TestData/DM1002_DM808T3_3
