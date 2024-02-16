source runstepper.sh
source setup.sh
dbname=bar
mode=$1
setupout=/dev/null
verbose=1

function setupinsertstest() {
	cdb2sql $dbname local "drop table if exists z"
	cdb2sql $dbname local "drop table if exists b"
	cdb2sql $dbname local "create table z(i decimal128)"
	cdb2sql $dbname local "create table b(i int)"
}

function undoinserts() {
	mode=$1
	bounce=$2
	numinserts=$3
	verbose=$4

	if (( bounce == 1 )); then
		setup $dbname
	fi
	setupinsertstest &> $setupout

	echo "1 set transaction chunk 2000" > stepperfile
	echo "2 set transaction ${mode} isolation" >> stepperfile
	echo "2 begin" >> stepperfile
	echo "2 select * from b" >> stepperfile
	echo "1 begin" >> stepperfile
	echo "1 insert into z(i) select 1 from generate_series(1, ${numinserts})" >> stepperfile # 500000
	echo "1 commit" >> stepperfile
	echo "2 select count(*) from z" >> stepperfile
	echo "2 commit" >> stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname stepperfile /dev/null
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)
	if (( verbose == 1 ));
	then
		echo -e "Time to run inserts test in $mode with $numinserts inserts: $elapsed seconds\n"
	else
		echo "$elapsed"
	fi

	if (( bounce == 1 )); then
		teardown $dbname
	fi
}
