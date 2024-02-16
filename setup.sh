declare dbpid

function setup() {
	~/bin/restartdb.sh $1 none /bb/comdb2a/mdouglas47/dbdir/ &> db &
	sleep 10
	dbpid=$(ps -ef | grep "./comdb2 $1" | awk '{print $2}' | head -1)
}

function teardown() {
	kill -9 $dbpid
}
