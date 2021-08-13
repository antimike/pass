#!/bin/bash
# Joins a template file to an updated version, possibly including fields not
# present in the original
# NOTE: WILL NOT WORK with YAML arrays!  Only use this for simple dict-style
# config files
# TODO: Write full YAML (-esque) merger
# TODO: Add usage information

original="$1"
update="$2"
eol="$(printf '\001')"

if [ ! -f "$original" ] || [ ! -f "$update" ]; then
    echo "Invalid filename" >&2
    exit 3
fi

join -t':' -j1 -a1 -a2 \
    <(sort -k1 "$update" | sed "s/$/${eol}/") \
    <(sort -k1 "$original") |
    grep -o "^[^${eol}]*${eol}" |
    sed "s/${eol}//g"
