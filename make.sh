# try to auto-determine TOP
for f in . .. ../.. ../../.. ../../../.. ../../../../.. ../../../../../.. ../../../../../../.. ../../../../../../../.. ../../../../../../../../.. ../../../../../../../../../..
do
	if [ -f $f/.top ]
	then
		make TOP=`cd $f && pwd` "$@"
		exit $?
	fi
done
echo "failed to find .top"
