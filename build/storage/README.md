# Description
IPDK Storage solution targets the audience which has existing custom storage
protocols or implementations of standards such as NVMe-over-Fabrics and wants
to accelerate them by means of a common storage solution across vendors
and platforms.

# Main components
The storage solution is represented by the following containers:
- _proxy-container_ which plays the role of an IPU and exposes the block
devices to a host platform.
- _storage-target_ which is deployed on a remote storage node exposing
ideal targets(ramdrives).
- _host-target_ which is responsible for running of fio traffic through
`proxy-container` to an ideal target within `storage-target`.

# Recipes
IPDK storage scenarios are described by recipes located in a dedicated
[recipes](recipes/README.md) directory.

# Tests
The storage solution is covered by [unit tests](tests/ut/) and
[integration tests](tests/it/).
