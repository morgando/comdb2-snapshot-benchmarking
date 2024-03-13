#!/bin/bash
source util/setup.sh
source impl/undodeletesimpl.sh
source impl/undoinsertsimpl.sh
source impl/undoupdatesimpl.sh

dbname=$RANDOM

add() { 
	echo $1 $2 | awk '{print $1 + $2}' 
}

div() {
	echo $1 $2 | awk '{print $1/$2}'
}

function verify() {
	tfunc=$1
	args=$2
	verbose=0
	bounce=0
	verify=1

	for mode in snapshot modsnap;
	do
		res=$($tfunc $mode $bounce $args $verbose $verify)
		if [[ $res ]];
		then
			echo $res
		fi
	done
}

setup $dbname

for i in 10 100 1000 10000 100000;
do
	verify undodeletes $i
done
for i in 10 100 1000 10000 100000;
do
	verify undoinserts $i
done
for i in 10 100 1000 5000;
do
	verify undoupdates $i
done

teardown
