# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

from pci  import PciAddress

class SmaHandleError(ValueError):
    pass


class SmaHandle:
    def is_virtual(self) -> bool:
        raise NotImplementedError()

    def get_pci_address(self) -> PciAddress:
        raise NotImplementedError()

    def get_protocol(self) -> str:
        raise NotImplementedError()
