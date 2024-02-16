source runstepper.sh
source setup.sh
tier=local
dbname=bar
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

function undoupdates() {
	mode=$1
	bounce=$2
	numupdates=$3
	verbose=$4

	if (( bounce == 1 )); then
		setup $dbname
	fi
	setupupdatestest $numupdates &> $setupout
	
	echo "1 set transaction ${mode} isolation" > stepperfile
	echo "2 set transaction ${mode} isolation" >> stepperfile
	echo "2 begin" >> stepperfile
	echo "2 select * from b" >> stepperfile
	echo "1 update z set i=i+1000" >> stepperfile
	echo "2 select avg(i) from z" >> stepperfile
	echo "2 commit" >> stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname stepperfile out
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)

	if (( verbose == 1 ));
	then
		echo -e "Time to run updates test in $mode with $numupdates updates: $elapsed seconds\n"
	else
		echo "$elapsed"
	fi

	if (( bounce == 1 )); then
		teardown $dbname
	fi
}
