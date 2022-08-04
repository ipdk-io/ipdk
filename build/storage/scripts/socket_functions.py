import logging
import re
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


def send_command_over_unix_socket_and_no_word_found(
    sock: str, cmd: str, wait_for_secs: float, word: str
) -> int:
    out = send_command_over_unix_socket(sock=sock, cmd=cmd, wait_for_secs=wait_for_secs)
    return 1 if re.search(word, out) else 0


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
