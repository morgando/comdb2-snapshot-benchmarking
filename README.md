# Comdb2 Snapshot Benchmarking

This repo is a benchmarking suite intended to compare the performance of the current snapshot implementation, the new, replacement snapshot implementation, and the default isolation mode.

Throughout the rest of this document the replacement snapshot implementation will be referred to as 'modsnap'. This stands for "MOrgan Douglas SNAPshot".......so hopefully it is good :'D.

## Setup

Run `. ./env` to setup your environment and `./configure.sh` to build dependencies.

The benchmarking suite will store a db in a subdirectory of this repo. If you would rather it store the db somewhere else, specify your preferred directory by setting the environment variable `COMDB2_SNAPSHOT_BENCHMARKING_DBDIR`.

## Benchmarking

The benchmarking suite is composed of tests. The benchmarking task emits the average execution time of each test running in each isolation level over 50 iterations. See the section below for more information about the tests.

To run the benchmarking task, run `./benchmark.sh`.

## Verify

The verify suite runs every test in the benchmarking suite against the two snapshot implementations and emits a message for each test that produces incorrect output.

To run the verify task, run `./verify.sh`.

## Tests

There are 3 tests:
- undodeletes. In this case one transaction reads while another deletes.
- undoinserts. In this case one transaction reads while another inserts.
- undoupdates. In this case one transaction reads while another updates.

(In these tests, if the reading transaction is running in one of the snapshot modes, then the modifications made by the other transaction will need to be undone.)


Each test is implemented in a file ending in `impl`:
- undodeletes is implemented in `undodeletesimpl.sh`
- undoinserts is implemented in `undoinsertsimpl.sh`
- undoupdates is implemented in `undoupdatesimpl.sh`

Each test has a driver that can be used to run it from the command line:
- the undodeletes driver is called `undodeletes.sh`
- the undoinserts driver is called `undoinserts.sh`
- the undoupdates driver is called `undoupdates.sh`

All 3 drivers are invoked in the same way:
- `./undodeletes.sh <mode> <numdeletes> <verify>`
- `./undoinserts.sh <mode> <numinserts> <verify>`
- `./undoupdates.sh <mode> <numupdates> <verify>`

where `mode` specifies the mode of the reading transaction (and is one of: "snapshot", "modsnap", "blocksql") and `verify` toggles verify mode.

If verify is not toggled, then the driver outputs the amount of time it took to run the test. If verify mode is toggled, then the driver outputs nothing if the test produces the correct output or an error message if it does not.

## Results

Click [here](https://docs.google.com/spreadsheets/d/1PO6HQhKQYZwvqJZr1z2XQFbazWp7D_O4tYZLlfSaKEc/edit?usp=sharing) to view the summarized results of one benchmark task that I ran.
