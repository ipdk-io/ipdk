# Setup
To prepare the environment setup for testing follow these steps:
1. Copy `setup.sh` to your home directory and run it. This will clone the required repositories.
```bash
. setup.sh
```
2. Navigate to the `storage` directory and run integration test to build docker images.
```bash
sudo tests/it/run.sh hot-plug
```
3. Fill `python_system_tools/data.json` with ip addresses, user name and password.
4. Run ptf setup tests within `ptf_test` directory.
```bash
. run_setup_tests.sh
```