#!/usr/bin/env python
#
# Copyright (C) 2022 Intel Corporation
# SPDX-License-Identifier: Apache-2.0
#
import logging
import socket

logging.root.setLevel(logging.CRITICAL)


def send_command_over_unix_socket(sock: str, cmd: str, wait_for_secs: float) -> str:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(wait_for_secs),
        out = []
        try:
            s.connect(sock)
            cmd = f"{cmd}\n".encode()
            s.sendall(cmd)
            while data := s.recv(256):
                out.append(data)
        except socket.timeout:
            logging.error("Timeout exceeded")
        return b"".join(out).decode()


def get_output_from_unix_socket(sock: str, wait_for_secs: float) -> str:
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(wait_for_secs)
        out = []
        try:
            s.connect(sock)
            while data := s.recv(256):
                out.append(data)
        except socket.timeout:
            logging.error("Timeout exceeded")
        return b"".join(out).decode()
