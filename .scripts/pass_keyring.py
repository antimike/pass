"""
passkeyring.py

An implementation of the keyring API for the Unix `pass` CLI password manager

---
Dependencies:
  Standard:
    - pass
  Pass scripts:
    Mine / under development:
      - pass-yaml
      - pass-create
      - pass-getfrom
      - pass-annotate
    Third-party:
      - pass-tail
  Miscellaneous:
    - vipe
---
"""
from keyring.backend import KeyringBackend

class PassKeyring(KeyringBackend):
    def supported(self):
        # TODO: Test for existence of pass directory and command
        return 1
    def get_password(self, service, username):
        pass
    def set_password(self, service, username, password):
        pass
    def delete_password(self, service, username):
        pass
