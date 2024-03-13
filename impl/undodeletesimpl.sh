source util/runstepper.sh
source util/setup.sh
declare dbname
verbose=1

function setupdeletetest() {
	numrecords=$1
	cdb2sql $dbname local "drop table if exists z"
	cdb2sql $dbname local "drop table if exists b"
	cdb2sql $dbname local "create table z(i decimal128)"
	cdb2sql $dbname local "create table b(i int)"
	cat << EOF | cdb2sql $dbname local - >/dev/null 2>&1
	set transaction chunk 2000
	begin
	insert into z select 1 from generate_series(1, $numrecords)
	commit
EOF
}

function undodeletesexpected() {
	numrecords=$1

	echo "done" > tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
	echo "(count(*)=$numrecords)" >> tmp/expected
	echo "done" >> tmp/expected
	echo "done" >> tmp/expected
}

function undodeletes() {
	mode=$1
	bounce=$2
	numdeletes=$3
	verbose=$4

	if (( verify == 1 )); then
		if [[ $mode == "blocksql" ]]; then
			echo "Verify can only be run with snapshot or modsnap"
			exit 1
		fi
		undodeletesexpected $numdeletes
	fi
	if (( bounce == 1 )); then
		dbname=$RANDOM
		setup $dbname
	fi
	setupdeletetest $numdeletes &> /dev/null

	echo "1 set transaction ${mode} isolation" > tmp/stepperfile
	echo "1 begin" >> tmp/stepperfile
	echo "1 select * from b" >> tmp/stepperfile
	echo "2 set transaction chunk 2000" >> tmp/stepperfile
	echo "2 begin" >> tmp/stepperfile
	echo "2 delete from z where i=1" >> tmp/stepperfile
	echo "2 commit" >> tmp/stepperfile
	echo "1 select count(*) from z" >> tmp/stepperfile
	echo "1 commit" >> tmp/stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname tmp/stepperfile tmp/out
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)

	if (( verify == 1 ));
	then
		cmp tmp/expected tmp/out &> /dev/null || echo "Running deletes test in $mode with $numdeletes deletes produced incorrect output"
	else 
		if (( verbose == 1 ));
		then
			echo -e "Time to run deletes test in $mode with $numdeletes deletes: $elapsed seconds\n"
		else
			echo "$elapsed"
		fi
	fi

	if (( bounce == 1 )); then
		teardown
	fi
}

