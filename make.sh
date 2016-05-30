#!/bin/sh

# helper for auto-setting ${TOP} environment variable:
# look for .top file in top-level directories

for f in \
. \
.. \
../.. \
../../.. \
../../../.. \
../../../../.. \
../../../../../.. \
../../../../../../.. \
../../../../../../../.. \
../../../../../../../../.. \
../../../../../../../../../.. \
../../../../../../../../../../.. \
../../../../../../../../../../../..
do
	if [ -f $f/.top ]
	then
		make TOP=`cd $f && pwd` "$@"
		exit $?
	fi
done
echo "failed to find .top"
