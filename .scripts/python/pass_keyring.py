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
import os, shlex
import logging
from keyring.backend import KeyringBackend
from subprocess import Popen, PIPE
from keyring.errors import PasswordSetError, PasswordDeleteError, InitError
from abc import ABCMeta, abstractmethod
from glob import glob
from functools import cached_property

logger = logging.getLogger(__name__)

PASSWORD_ERROR = "Could not perform action '%s' for password: service='%s', username='%s'"

# Not necessary (but instructive)---glob module can be used instead
_get_children(parent, extension, exclude=[".git"]):
    if not os.path.isdir(parent):
        raise ValueError("Argument must be a directory")
    for path, dirs, files in os.walk(parent):
        dirs[:] = [d for d in dirs if d not in exclude]
        for file in files:
            if file.endswith(extension):
                yield file

class Command(metaclass=ABCMeta):
    @classmethod
    @abstractmethod
    def options(cls):
        """The CLI options available with this command"""
        pass
    @property
    @abstractmethod
    def command(self):
        """The command line, suitable for use in a TTY"""
        pass
    def __init__(self, base, *flags, **opts):
        pass

class PassAdapter:
    """Representation of the Unix `pass` password store and associated commands"""
    default_dirs = [
        os.getenv("PASSWORD_STORE_DIR"),
        os.getenv("PASS_DIR"),
        os.join(os.getenv("HOME"), ".password-store")
    ]
    def __init__(self, pass_dir=None):
        while pass_dir is None or not os.path.isdir(pass_dir):
            try:
                pass_dir = PasswordStore.default_dirs.pop()
            except IndexError:
                raise PassError("Could not locate a suitable password store")
        self.pass_dir = pass_dir
        self._command = []
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
        self.pass_dir = os.environ.get("PASS_DIR", os.environ.get("HOME") + "/.password-store")

    @properties.ClassProperty
    @classmethod
    def priority(cls):
        # TODO: Improve this
        # Per the docs, >= 1 --> recommended, so for now this should be OK
        return 2
    def supported(self):
        # TODO: Test for existence of pass directory and command
        return subprocess.run(["which", "pass"])
        return 1
    def get_password(self, service, username):
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
