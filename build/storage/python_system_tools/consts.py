import os.path
import re
from pathlib import Path

# paths on master machine
HOME_PATH = str(Path.cwd())
HOME_PATH = re.search(pattern=r"\/\w*\/\w*\/", string=HOME_PATH).group(0)
WORKSPACE_PATH = os.path.join(HOME_PATH, "IPDK_workspace")
SHARE_DIR_PATH = os.path.join(WORKSPACE_PATH, "SHARE")
SCRIPTS_PATH = os.path.join(WORKSPACE_PATH, "ipdk/build/storage/scripts")
