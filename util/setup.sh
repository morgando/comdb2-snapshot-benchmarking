declare dbpid

trap "teardown 1" INT

function pingdb() {
	dbname=$1

	out=$(cdb2sql $dbname local "select 1")

	if [[ $out != "(1=1)" ]];
	then
		echo "Failed to ping db after starting it"
		exit 1
	fi
}

function setup() {
	dbname=$1

	dbpid=$(ps -ef | grep "./comdb2 $dbname" | grep -v grep | awk '{print $2}' | head -1)
	if [[ $dbpid ]];
	then
		echo "db with name $dbname is already running locally. Please kill it or use a different name."
		exit 1
	fi
	
	if [[ -z "${COMDB2_SNAPSHOT_BENCHMARKING_DBDIR}" ]]; then
		dir=tmp/dbdir
	else
		dir=$COMDB2_SNAPSHOT_BENCHMARKING_DBDIR
	fi

	mkdir $dir &> /dev/null
	printf "name $dbname\ndir $(realpath $dir)\nenable_snapshot_isolation" > tmp/db.lrl
	./tmp/comdb2/build/db/comdb2 $dbname --create --lrl tmp/db.lrl &> /tmp/db
	./tmp/comdb2/build/db/comdb2 $dbname --lrl tmp/db.lrl &> tmp/db &
	sleep 15

	pingdb $dbname
	dbpid=$(ps -ef | grep "./comdb2 $dbname" | grep -v grep | awk '{print $2}' | head -1)
	if [[ $dbpid ]];
	then
		echo "started db with pid $dbpid"
	fi
}

function teardown() {
	die=$1

	if [[ $dbpid ]];
	then
		kill -9 $dbpid
		echo "killed $dbpid"
	fi

	if [[ $die ]];
	then
		exit 1
	fi
}
