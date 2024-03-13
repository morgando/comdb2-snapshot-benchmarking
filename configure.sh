mkdir tmp
git clone https://github.com/morgando/comdb2.git tmp/comdb2
cd tmp/comdb2
git checkout test_branch
mkdir build
cd build
cmake ..
make -j4
make -C tests/tools
cd ../../..
pmux -n &> /dev/null
export CDB2_CONFIG=./tmp/comdb2db.cfg
echo "comdb2_config:default_type=local" > $CDB2_CONFIG
