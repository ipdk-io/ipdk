# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#

import logging
import os
import pathlib
from os import listdir
from os.path import isfile, join
from types import ModuleType
from typing import Callable
from typing import Optional
from device_exerciser_if import DeviceExerciserIf
from importlib.machinery import SourceFileLoader


MAKE_DEVICE_EXERCISER_FUNCTION_NAME = "make_device_exerciser"


class GetCustomizationError(RuntimeError):
    pass


def _py_files_in_dir_exist(dir: str) -> bool:
    return len(_get_all_py_files_in_dir(dir)) != 0


def _get_all_py_files_in_dir(dir: str) -> list[str]:
    return [f for f in listdir(dir) if isfile(join(dir, f)) and f.endswith(".py")]


def _load_module(module_path: str) -> ModuleType:
    module_name = pathlib.Path(module_path).stem
    return SourceFileLoader(module_name, module_path).load_module()


def _find_make_device_exerciser_in_module(module: ModuleType) -> Optional[Callable]:
    exerciser = getattr(module, MAKE_DEVICE_EXERCISER_FUNCTION_NAME, None)
    if callable(exerciser):
        logging.warning(f"Found non-callable {MAKE_DEVICE_EXERCISER_FUNCTION_NAME}")
        return exerciser
    else:
        return None


def _find_all_make_device_exercisers_in_dir(dir: str) -> list[Callable]:
    make_device_exercisers = []
    py_files = _get_all_py_files_in_dir(dir)
    for py_file in py_files:
        module = _load_module(join(dir, py_file))
        device_exerciser = _find_make_device_exerciser_in_module(module)
        if device_exerciser:
            make_device_exercisers.append(device_exerciser)
    return make_device_exercisers


def find_make_custom_device_exerciser(
    customization_dir: str,
) -> Optional[Callable]:
    if not customization_dir:
        logging.info("Customization dir is not set")
        return None
    if not os.path.isdir(customization_dir):
        raise GetCustomizationError(
            "Customization directory '" + str(customization_dir) + "' is not directory"
        )

    if _py_files_in_dir_exist(customization_dir):
        make_device_exercisers = _find_all_make_device_exercisers_in_dir(
            customization_dir
        )

        if len(make_device_exercisers) > 1:
            raise GetCustomizationError(
                "Function to create device exerciser exists "
                + str(make_device_exercisers)
                + " in more than one module in '"
                + customization_dir
                + "'"
            )
        if len(make_device_exercisers) == 0:
            raise GetCustomizationError(
                "No function to create customized device exerciser is found in dir '"
                + customization_dir
                + "'"
            )
        return make_device_exercisers[0]
    else:
        return None
