source impl/undoupdatesimpl.sh

mode=$1
numupdates=$2
verify=$3
verbose=1
bounce=1

undoupdates $mode $bounce $numupdates $verbose $verify
