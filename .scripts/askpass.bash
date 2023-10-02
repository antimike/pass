#!/bin/env bash
# Script to be used with sudo in "batch" mode, e.g.:
# 	SUDO_ASPASS=/home/hactar/.password-store/.scripts/askpass.bash tsp sudo do-stuff

if [[ "$USER" == "hactar" ]]; then
	pass show personal/macbook/hactar
else
	echo "Error: attempted to run ${BASH_SOURCE[0]} as user $USER" >&2
fi
