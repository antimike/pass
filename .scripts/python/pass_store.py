"""Python interface to `pass` CLI"""
import os, shlex
from subprocess import Popen, PIPE
from .pass_error import PassError

class PassStore:
    """Simple Python interface to the Unix `pass` CLI"""
    @staticmethod
    def _execute(pass_cmd, *args, stdin=None, **opts):
        """Executes `pass` CLI command, assuming short-form options"""
        cmd = ["pass", shlex.quote(pass_cmd)]
        for key, val in opts.items():
            cmd.append(shlex.quote('-' + key))
            if val is not None:
                cmd.append(shlex.quote(val))
        cmd.extend([shlex.quote(arg) for arg in args])
        proc = Popen(cmd, stdin=PIPE, stdout=PIPE, stderr=PIPE, text=True)
        result, stderr = proc.communicate(stdin)
        if proc.returncode != 0:
            raise PassError(
                "Error running command '%s':\n%s" % (cmd, stderr)
            )
        return {"stdout": result, "stderr": stderr}
    @staticmethod
    def _deserialize(line):
        print(f"DEBUG: {line}")
        if len(split := line.split("=")) > 1:
            return (split[0].strip(), "=".join(split[1:]).strip())
        elif len(split := line.split(":")) > 1:
            return (split[0].strip(), ":".join(split[1:]).strip())
        else:
            return ("password", line)
    @staticmethod
    def _serialize(*lines, **kwargs):
        return lines + ['='.join(pair) for pair in kwargs.items()]
    @staticmethod
    def get(path):
        """Returns a dict with the password (assumed to be the top line of the passfile) and any other attributes stored in the file"""
        lines = PassStore._execute("show", path)["stdout"].split("\n")
        return {**dict(map(PassStore._deserialize, lines)), "password": lines[0]}
    @staticmethod
    def set(path, password, **kwargs):
        """Stores a password and any additional passed attributes in a passfile"""
        PassStore._execute(
            "insert",
            path,
            stdin='\n'.join(PassStore._serialize(password, **kwargs)),
            f=None,     # "force" flag
            e=None      # "don't edit" flag
        )
