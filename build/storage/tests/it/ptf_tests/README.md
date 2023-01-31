# Description
PTF tests are integration tests based on PTF library.

# Run tests
1. Create python environment by issuing `bash create_python_environment.sh` within storage/tests/it/scripts directory.
2. Set configs in .env file in storage/tests/it/ptf_scripts/system_tools directory.
   You can find dot_env_template in this directory.
3. All platforms for testing provided in config file must be added to ~/.ssh/known_hosts.
4. Execute command `bash run_ptf_tests.sh` within storage/tests/it/scripts directory.
