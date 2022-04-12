#!/bin/bash
# Decrypts, edits, and re-encrypts a file encrypted with GPG
# TODO: Replace `vipe` with direct `nvim` invocation?

source $BASH_INCLUDE

set -e
set -o pipefail

typeset file="$1"
typeset dest="${2:-${file}}"

# NOTE: `mktemp --dry-run` is marked "unsafe" in the docs
fifo="$(mktemp)" && rm -f "$fifo" && mkfifo "$fifo" ||
    die 27 "Unable to create FIFO"

typeset key_regex="ID \([A-Z0-9]\+\)"
if [ -f "$file" ]; then
    gpg -d "$file" 2>&1 |
        tee >(grep -o "$key_regex" | cut -f2 -d' ' >${fifo} &) |
        sed -n '3,$p' |
        vipe |
        gpg -e -a -r $(cat <${fifo}) >"$dest"
else
    die 23 "File '$file' does not exist"
fi

exit $?
