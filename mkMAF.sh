#!/bin/bash
SDIR=$(cd `dirname $0`; pwd)
/opt/bin/python2.7 $SDIR/MkMAF $*
