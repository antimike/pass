#!/bin/bash
# Joins a template file to an updated version, possibly including fields not
# present in the original
# NOTE: WILL NOT WORK with YAML arrays!  Only use this for simple dict-style
# config files
# TODO: Write full YAML (-esque) merger
# TODO: Add usage information

# Original implementation:
# original="$1"
# update="$2"
# eol="$(printf '\001')"

# if [ ! -f "$original" ] || [ ! -f "$update" ]; then
#     echo "Invalid filename" >&2
#     exit 3
# fi

# join -t':' -j1 -a1 -a2 \
#     <(sort -k1 "$update" | sed "s/$/${eol}/") \
#     <(sort -k1 "$original") |
#     grep -o "^[^${eol}]*${eol}" |
#     sed "s/${eol}//g"

# This is...fragile.  If the merged files aren't too different, then YAML arrays
# should be handled correctly, but this shouldn't be relied upon.
awk '
    BEGIN {FS=":"; OFS=":"; fnum=0;}
    FNR==1 {fnum++;}
    {print fnum, FNR, $0;}
' "$@" | sort -t':' -k3 -k1 | awk '
    BEGIN {FS=":";}
    NR==1 {field=" " $3;}
    field==$3 {next;}
    {
        field=$3;
        print $3 (NF > 3 ? ": " $4 : "")}   # Avoids trailing colon issues
'
