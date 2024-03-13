source util/runstepper.sh
source util/setup.sh
tier=local
declare dbname
setupout=/dev/null
verbose=1

function setupupdatestest() {
	numrecords=$1
	cdb2sql $dbname $tier "drop table if exists z" 
	cdb2sql $dbname $tier "drop table if exists b"
	cdb2sql $dbname $tier "create table z(i decimal128, id longlong autoincrement)" 
	cdb2sql $dbname $tier "create table b(i int)" 
	cdb2sql $dbname $tier "insert into z(i) select 1 from generate_series(1, ${numrecords})" 
}

function undoupdatesexpected() {
	numrecords=$1

	echo "done" > tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "(rows updated=${numrecords})" >> tmp/expected
	echo "done" >> tmp/expected
	echo "(avg(i)='1')" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
}

function undoupdates() {
	mode=$1
	bounce=$2
	numupdates=$3
	verbose=$4
	verify=$5

	if (( numupdates > 50000 )); then
		echo "Maximum number of updates is 50000"
		exit 1
	fi
	if (( verify == 1 )); then
		if [[ $mode == "blocksql" ]]; then
			echo "Verify can only be run with snapshot or modsnap"
			exit 1
		fi
		undoupdatesexpected $numupdates
	fi

	if (( bounce == 1 )); then
		dbname=$RANDOM
		setup $dbname
	fi
	setupupdatestest $numupdates &> $setupout
	
	echo "1 set transaction ${mode} isolation" > tmp/stepperfile
	echo "2 set transaction ${mode} isolation" >> tmp/stepperfile
	echo "2 begin" >> tmp/stepperfile
	echo "2 select * from b" >> tmp/stepperfile
	echo "1 update z set i=i+1000" >> tmp/stepperfile
	echo "2 select avg(i) from z" >> tmp/stepperfile
	echo "2 commit" >> tmp/stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname tmp/stepperfile tmp/out
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)

	if (( verify == 1 ));
	then
		cmp tmp/expected tmp/out &> /dev/null || echo "Running updates test in $mode with $numupdates updates produced incorrect output"
	else
		if (( verbose == 1 ));
		then
			echo -e "Time to run updates test in $mode with $numupdates updates: $elapsed seconds\n"
		else
			echo "$elapsed"
		fi
	fi

	if (( bounce == 1 )); then
		teardown
	fi
}
