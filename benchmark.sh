#!/bin/bash
source setup.sh
source undodeletesutil.sh
source undoinsertsutil.sh
source undoupdatesutil.sh

dbname=bar

add() { 
	echo $1 $2 | awk '{print $1 + $2}' 
}

div() {
	echo $1 $2 | awk '{print $1/$2}'
}

function benchmark() {
	tfunc=$1
	itrs=$2
	args=$3
	verbose=0
	bounce=0

	for mode in blocksql snapshot modsnap;
	do
		total=0.0
		for i in $(seq $itrs);
		do
			res=$($tfunc $mode $bounce $args $verbose)
			total=$(add $total $res)
		done
		avg=$(div $total $itrs)
		echo "$mode $tfunc $args $avg"
	done

}

setup $dbname

for i in 10 100 1000 10000 100000;
do
	:
#	benchmark undodeletes 50 $i
done
for i in 10 100 1000 10000 100000;
do
	benchmark undoinserts 50 $i
done
for i in 10 100 1000 5000;
do
	:
#	benchmark undoupdates 50 $i
done

teardown $dbname
