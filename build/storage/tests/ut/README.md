# Description
Unit tests covering services written for IPDK.

# Run unit tests
The command below builds all required dependencies and runs the unit tests
within the dedicated container.
```
$ ./run.sh
```

# Development
By means of the command below, a container will be started with test and source
files attached as volumes.
```
$ ./run.sh dev
```

In order to run the unit tests during a development session, run
`run_all_unit_tests.sh` within the started container.
```
$ /run_all_unit_tests.sh
```
