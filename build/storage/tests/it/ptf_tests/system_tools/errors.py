"""System tools errors"""


class ContainerNotRunningException(Exception):
    """Container is not currently running"""


class CommandException(Exception):
    """Custom Exception was risen during command execution"""


class VirtualizationException(Exception):
    """Virtualization may not be set properly"""


class MissingDependencyException(Exception):
    """Test environment dependency may not be set properly"""


class BusyPortException(Exception):
    """The requested port is occupied by another process"""


class CMDSenderPlatformNameException(Exception):
    """Incorrect CMD Sender platform"""
