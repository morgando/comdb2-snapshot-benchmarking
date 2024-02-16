source runstepper.sh
source setup.sh
dbname=bar
setupout=/dev/null
verbose=1

function setupdeletetest() {
	numrecords=$1
	cdb2sql $dbname local "drop table if exists z"
	cdb2sql $dbname local "drop table if exists b"
	cdb2sql $dbname local "create table z(i decimal128)"
	cdb2sql $dbname local "create table b(i int)"
	cat << EOF | cdb2sql $dbname local - >output.actual 2>&1
	set transaction chunk 2000
	begin
	insert into z select 1 from generate_series(1, $numrecords)
	commit
EOF
}

function undodeletes() {
	mode=$1
	bounce=$2
	numdeletes=$3
	verbose=$4

	if (( bounce == 1 )); then
		setup $dbname
	fi
	setupdeletetest $numdeletes &> $setupout

	echo "1 set transaction ${mode} isolation" > stepperfile
	echo "1 begin" >> stepperfile
	echo "1 select * from b" >> stepperfile
	echo "2 set transaction chunk 2000" >> stepperfile
	echo "2 begin" >> stepperfile
	echo "2 delete from z where i=1" >> stepperfile
	echo "2 commit" >> stepperfile
	echo "1 select count(*) from z" >> stepperfile
	echo "1 commit" >> stepperfile

	start_time=$(date +%s.%3N)
	runstepper $dbname stepperfile out
	end_time=$(date +%s.%3N)
	elapsed=$(echo "scale=3; $end_time - $start_time" | bc)

	if (( verbose == 1 ));
	then
		echo -e "Time to run deletes test in $mode with $numdeletes deletes: $elapsed seconds\n"
	else
		echo "$elapsed"
	fi

	if (( bounce == 1 )); then
		teardown $dbname
	fi
}

