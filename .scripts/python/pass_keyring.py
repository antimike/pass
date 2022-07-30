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
import logging
import os
import shlex
from functools import cached_property
from glob import glob
from subprocess import PIPE, Popen, run

from keyring.backend import KeyringBackend
from keyring.errors import InitError, PasswordDeleteError, PasswordSetError

from .pass_error import PassError

logger = logging.getLogger(__name__)

PASSWORD_ERROR = "Could not perform action '%s' for password: service='%s', username='%s'"

class PassAdapter:
    """Representation of the Unix `pass` password store and associated commands"""
    default_dirs = [
        os.getenv("PASSWORD_STORE_DIR"),
        os.path.join(os.getenv("HOME"), ".password-store")
    ]
    def __init__(self, pass_dir=None):
        self.pass_dir = pass_dir or os.path.join(os.getenv("HOME"), ".password-store")
        if pass_dir is None or not os.path.isdir(pass_dir):
            raise PassError("Pass store '%s' is not a valid directory" % pass_dir)
        self.command = []
    def search(self, **kwargs):
        """Search for passfiles with the provided user / service / url"""
        raise NotImplementedError
    def get_path(self, service, username):
        return shlex.quote(os.path.join(username, service))
    def _execute(self, pass_cmd, *args, **opts):
        """Executes `pass` CLI command, assuming short-form options"""
        cmd = ["pass", shlex.quote(pass_cmd)]
        for key, val in opts.items():
            cmd.append(shlex.quote(key))
            if val is not None:
                cmd.append(shlex.quote(val))
        cmd.extend([shlex.quote(arg) for arg in args])
        proc = Popen(cmd, stdin=PIPE, stdout=PIPE, text=True)
        result, stderr = proc.communicate(arg)
        if proc.returncode != 0:
            raise PassError(
                "Error running command '%s':\n%s" % (self.command, stderr)
            )
        return result
    def get_password(self, service, username):
        return self._execute()
    def set_password(self, service, username, interactive=False):
        self._command = [ "pass", "insert", self.get_path(service, username) ]
        if not interactive:
            self._command.extend(["-f", "-e"])
    def delete_password(self, service, username):
        pass

class PassKeyring(KeyringBackend):
    def __init__(self):
        self.pass_dir = os.environ.get(
            "PASSWORD_STORE_DIR",
            os.path.join(os.environ.get("HOME"), ".password-store")
        )

    @classmethod
    def priority(cls):
        # TODO: Improve this
        # Per the docs, >= 1 --> recommended, so for now this should be OK
        return 2
    def supported(self):
        return run(["which", "pass"])
    def get_password(self, service, username):
        """Assumes the passfile is stored at ${PASS_DIR}/${service}/${username}"""
        proc = Popen(
            ["pass", "show", os.path.join(service, username)],
            stdout=PIPE,
            text=True
        )
        return proc.communicate()
    def set_password(self, service, username, password):
        proc = Popen(
            ["pass",
             "insert",
             "-f",
             "-e",
             os.path.join(service, username)],
            stdin=PIPE,
            stdout=PIPE,
            text=True
        )
        output = proc.communicate(password)
        if proc.returncode != 0:
            raise PasswordSetError(
                PASSWORD_ERROR % ("set", service, username)
            )
    def delete_password(self, service, username):
        proc = Popen(
            ["pass", "rm", "-f", os.path.join(service, username)],
            stdout=PIPE,
            text=True
        )
        proc.communicate()
        if proc.returncode != 0:
            raise PasswordDeleteError(
                PASSWORD_ERROR % ("delete", service, username)
            )
