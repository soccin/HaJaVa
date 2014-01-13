#!/bin/bash
SDIR=$(cd `dirname $0`; pwd)
/usr/bin/env python2.7 $SDIR/MkMAF $*
