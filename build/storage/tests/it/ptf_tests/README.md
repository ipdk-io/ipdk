# Description
PTF tests are integration tests based on PTF library. This library was chosen for the matter of unification of testing framework between development teams. 

# Run tests
1. Firstly, create python environment. To do this, run command `bash create_python_environment.sh` within storage/tests/it/ptf_scripts directory.
2. Next, set configs in .env file in storage/tests/it/ptf_scripts/system_tools directory.
   You can find dot_env_template in this directory.
3. For running the tests execute command `bash run_ptf_tests.sh` within storage/tests/it/ptf_scripts directory.
