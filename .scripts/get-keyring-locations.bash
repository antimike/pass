#!/bin/bash

# Location of config file
python -c "import keyring.util.platform_; print(keyring.util.platform_.config_root())"

# Location of keyring data
python -c "import keyring.util.platform_; print(keyring.util.platform_.data_root())"
