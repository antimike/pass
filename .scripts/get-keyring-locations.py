#!/bin/env python3

from keyring.util import platform_ as platform

print(f"Keyring config: {platform.config_root()}")
print(f"Keyring data: {platform.data_root()}")
