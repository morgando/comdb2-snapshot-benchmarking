source util/runstepper.sh
source util/setup.sh
declare dbname
mode=$1
setupout=/dev/null
verbose=1

function setupinsertstest() {
	cdb2sql $dbname local "drop table if exists z"
	cdb2sql $dbname local "drop table if exists b"
	cdb2sql $dbname local "create table z(i decimal128)"
	cdb2sql $dbname local "create table b(i int)"
}

function undoinsertsexpected() {
	echo "done" > tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "(count(*)=0)" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
}

function undoinserts() {
	mode=$1
	bounce=$2
	numinserts=$3
	verbose=$4
	verify=$5

	if (( verify == 1 )); then
		if [[ $mode == "blocksql" ]]; then
			echo "Verify can only be run with snapshot or modsnap"
			exit 1
		fi
		undoinsertsexpected
	fi
	if (( bounce == 1 )); then
		dbname=$RANDOM
		setup $dbname
	fi
	setupinsertstest &> $setupout

	echo "1 set transaction chunk 2000" > tmp/stepperfile
	echo "2 set transaction ${mode} isolation" >> tmp/stepperfile
	echo "2 begin" >> tmp/stepperfile
	echo "2 select * from b" >> tmp/stepperfile
	echo "1 begin" >> tmp/stepperfile
	echo "1 insert into z(i) select 1 from generate_series(1, ${numinserts})" >> tmp/stepperfile # 500000
	echo "1 commit" >> tmp/stepperfile
	echo "2 select count(*) from z" >> tmp/stepperfile
	echo "2 commit" >> tmp/stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname tmp/stepperfile tmp/out
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)
	if (( verify == 1 )); then
		cmp tmp/expected tmp/out &> /dev/null || echo "Running inserts test in $mode with $numinserts inserts produced incorrect output"
	else
		if (( verbose == 1 ));
		then
			echo -e "Time to run inserts test in $mode with $numinserts inserts: $elapsed seconds\n"
		else
			echo "$elapsed"
		fi
	fi

	if (( bounce == 1 )); then
		teardown
	fi
}
