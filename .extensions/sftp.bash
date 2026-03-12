#!/bin/bash

if ! command -v yq >/dev/null 2>&1; then
  echo "Please install yq" >&2
  exit 2
fi

passfile="$1"
if [[ -z "$passfile" ]]; then
  echo "Please provide passfile name" >&2
  exit 1
fi

data="$(pass show "$passfile")"
yaml="$(<<<"$data" sed 1d | yq .)"
if (($?)); then
  echo "Could not parse contents of passfile as YAML" >&2
  exit 3
fi

username="$(<<<"$yaml" yq -r .username)"
password="$(<<<"$data" head -1)"
server="$(<<<"$yaml" yq -r .server)"
if [[ "$server" == "null" ]]; then
  server="$(<<<"$yaml" yq -r .url)"
fi

if [[ "$username" == "null" ]] || [[ "$server" == "null" ]]; then
  echo "Did not find expected YAML key 'server' or 'url'" >&2
  exit 4
fi

# sftp "${username}@${server}"
pass show -c "$passfile" >/dev/null 2>&1
cat <<SH
export SFTP_USERNAME="$username"
export SFTP_SERVER="$server"
SH
