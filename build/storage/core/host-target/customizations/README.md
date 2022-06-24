# How to add customization to run fio traffic
If a customized device exerciser is needed on host-target, the required steps
should be applied:
1. Create a class inheriting `DeviceExerciserIf` defined in
`device_exerciser_if.py` file. Within that class, any behavior can be applied
to run traffic. The file should be placed into a separate directory within
`customizations` directory. For example:
```
# customizations/target/custom_device_exerciser.py
import device_exerciser_if

class Exerciser(device_exerciser_if.DeviceExerciserIf):
    def run_fio(self, device_handle, fio_args):
        return 'ok'
```

2. Create a file with a single function with the following python signature
`def make_device_exerciser() -> DeviceExerciserIf:` This function should create
an instance of a class created on step 1. Additionally, in this file we need to
add to `PYTHONPATH` the directory where this file is located.
For example:
```
# customizations/make_custom_device_exerciser.py
import sys
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(SCRIPT_DIR)

import target.custom_device_exerciser

def make_device_exerciser():
    return target.custom_device_exerciser.Exerciser()
```

After those steps, the overall structure might look like this:
```
.
└── customizations
    ├── target
    │   └── custom_device_exerciser.py
    └── make_custom_device_exerciser.py
```

At this stage there are the following options to add the created customization
to the 'host-target` container.
1. Add the customization at build time:
a. Make sure `host-target` image is not created.
b. Place the customization content into the directory with this README
file.
c. Run `scripts/run_host_target_container.sh` script to build `host-target` with
provided customization.
Also, this customization is included in any commands which perform
`host-target` builds e.g. `scripts/run_vm.sh` or the integration tests run.

2. Add the customization at container start:
Run `CUSTOMIZATION_DIR=<path_to_customizations> scripts/run_host_target_container.sh`
script.
`CUSTOMIZATION_DIR` can be any directory within the filesystem with appropriate
permissions but not the directory with this README.
