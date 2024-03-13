source impl/undodeletesimpl.sh

mode=$1
bounce=1
verbose=1
numdeletes=$2
verify=$3

undodeletes $mode $bounce $numdeletes $verbose $verify
