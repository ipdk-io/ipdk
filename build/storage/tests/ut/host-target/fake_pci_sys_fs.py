#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import os
import glob
import shutil
from helpers.file_helpers import read_file, write_file
from pci import PciAddress

# TODO create tests which are run against this fake fs and real sysfs
class FakePciSysFs:
    def __init__(self, fake_fs, driver_name, vfs_base_bus=0xB0) -> None:
        self.fs = fake_fs
        self.vf_base_bus = vfs_base_bus
        self.driver_name = driver_name
        self.need_to_bind_device_to_driver = True
        self.need_to_unbind_device_from_driver = True
        self.fs.create_file(self.get_bind_path())
        self.fs.create_file(self.get_unbind_path())
        self.write_file_with_sysfs_effect = self.get_write_file_wrapper()

    def _sriov_vfs_set(self, file, content):
        numvfs = int(content)
        pci_addr = PciAddress(os.path.basename(os.path.dirname(file)))
        if numvfs == 0:
            self._disable_sriov(pci_addr)
        elif numvfs > 0:
            initial_vfs = int(read_file(self.get_sriov_numvfs_path(pci_addr)))
            total_vfs = int(read_file(self.get_sriov_totalvfs_path(pci_addr)))
            # Indicate that this behavior is not covered
            assert numvfs <= initial_vfs
            assert initial_vfs <= total_vfs
            self._enable_sriov(pci_addr, numvfs)
        else:
            # Indicate that this behavior is not covered
            assert False

    def _disable_sriov(self, pf_pci_addr):
        vfs = glob.glob(
            os.path.join(self.get_bound_device_path(pf_pci_addr), "virtfn*")
        )
        for vf in vfs:
            vf_pci_addr = PciAddress(os.path.basename(os.path.realpath(vf)))
            vf_plugged_device_dir = self.get_bound_device_path(vf_pci_addr)
            os.unlink(vf)
            if os.path.exists(vf_plugged_device_dir):
                os.unlink(vf_plugged_device_dir)
            shutil.rmtree(self.get_pci_device_path(vf_pci_addr))

    def _vf_index_to_pci_address(self, index):
        # This assumes ARI disabled
        bus = hex(index // 256 % 256 + self.vf_base_bus)[2:].zfill(2)
        device = hex((index // 8 % 32))[2:].zfill(2)
        function = hex(index % 8)[2:].zfill(1)
        return PciAddress(f"0000:{bus}:{device}.{function}")

    def _enable_sriov(self, pf_pci_addr, numvfs):
        plugged_pf_dir = self.get_bound_device_path(pf_pci_addr)
        if os.path.exists(plugged_pf_dir):
            # TODO handle case when vf numbers > total
            for i in range(numvfs):
                vf_pci_addr = self._vf_index_to_pci_address(i)
                self.create_pci_device(vf_pci_addr)
                self.fs.create_symlink(
                    self.get_physfn_path(vf_pci_addr),
                    self.get_pci_device_path(pf_pci_addr),
                )
                self.fs.create_symlink(
                    self.get_virtfn_path(pf_pci_addr, i),
                    self.get_pci_device_path(vf_pci_addr),
                )
        else:
            assert False

    def create_pci_device(self, pci_addr):
        self.fs.create_file(self.get_driver_override_path(pci_addr), contents="(null)")
        self.fs.create_file(self.get_enable_path(pci_addr), contents="0")

    def create_pci_device_with_sriov(self, pci_addr, max_vfs):
        self.create_pci_device(pci_addr)

        self.fs.create_file(self.get_sriov_numvfs_path(pci_addr))
        write_file(self.get_sriov_numvfs_path(pci_addr), 0)

        self.fs.create_file(self.get_sriov_totalvfs_path(pci_addr))
        write_file(self.get_sriov_totalvfs_path(pci_addr), max_vfs)

        self.fs.create_file(self.get_sriov_drivers_autoprobe_path(pci_addr))
        write_file(self.get_sriov_drivers_autoprobe_path(pci_addr), 1)

    def create_pci_device_with_bound_driver_and_enabled_sriov(self, pci_addr, max_vfs):
        self.create_pci_device_with_sriov(pci_addr, max_vfs)
        self.write_file_with_sysfs_effect(self.get_bind_path(), pci_addr)
        self.write_file_with_sysfs_effect(
            self.get_sriov_drivers_autoprobe_path(pci_addr), 0
        )
        self.write_file_with_sysfs_effect(
            self.get_sriov_numvfs_path(pci_addr),
            max_vfs,
        )

    def do_not_bind_device_to_driver(self):
        self.need_to_bind_device_to_driver = False

    def do_not_unbind_device_from_driver(self):
        self.need_to_unbind_device_from_driver = False

    def bind_pci_device_to_driver(self, pci_addr):
        self.fs.create_symlink(
            self.get_bound_device_path(str(pci_addr)),
            self.get_pci_device_path(pci_addr),
        )
        write_file(self.get_enable_path(pci_addr), 1)

    def unbind_pci_device_to_driver(self, pci_addr):
        write_file(self.get_enable_path(pci_addr), 0)
        os.remove(self.get_bound_device_path(pci_addr))

    def get_write_file_wrapper(self):
        def write_file_wrapper(file, content):
            write_file(file, content)

            if file == self.get_bind_path():
                if self.need_to_bind_device_to_driver:
                    self.bind_pci_device_to_driver(PciAddress(str(content)))
                else:
                    self.need_to_bind_device_to_driver = True
            elif file == self.get_unbind_path():
                if self.need_to_unbind_device_from_driver:
                    self.unbind_pci_device_to_driver(PciAddress(str(content)))
                else:
                    self.need_to_unbind_device_from_driver = True
            elif os.path.basename(file) == "sriov_numvfs":
                self._sriov_vfs_set(file, str(content))

        return write_file_wrapper

    def get_read_file_wrapper(self):
        def read_file_wrapper(file):
            return read_file(file)

        return read_file_wrapper

    def get_sriov_numvfs_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/sriov_numvfs"

    def get_sriov_totalvfs_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/sriov_totalvfs"

    def get_sriov_drivers_autoprobe_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/sriov_drivers_autoprobe"

    def get_driver_override_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/driver_override"

    def get_enable_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/enable"

    def get_virtfn_path(self, pci_addr, index):
        return f"/sys/bus/pci/devices/{pci_addr}/virtfn{index}"

    def get_bind_path(self):
        return f"/sys/bus/pci/drivers/{self.driver_name}/bind"

    def get_unbind_path(self):
        return f"/sys/bus/pci/drivers/{self.driver_name}/unbind"

    def get_bound_device_path(self, pci_addr):
        return f"/sys/bus/pci/drivers/{self.driver_name}/{pci_addr}"

    def get_pci_device_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}"

    def get_physfn_path(self, pci_addr):
        return f"/sys/bus/pci/devices/{pci_addr}/physfn"
