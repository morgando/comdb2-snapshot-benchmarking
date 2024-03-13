source impl/undoinsertsimpl.sh

mode=$1
numinserts=$2
verify=$3
bounce=1
verbose=1

undoinserts $mode $bounce $numinserts $verbose $verify
