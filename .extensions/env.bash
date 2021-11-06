#!/bin/bash
# Print a script to assign environment variables based on
# (1) a YAML specification file, and
# (2) credentials stored in the `pass` store.
# If the file $PASS_DIR/.env.yaml exists and is readable, then it will be
# processed **before** any user-provided files.
# Options:
#     -r/--reload     Printed script will assign all specified variables, even if
#                     already assigned
#     -q/--quiet      Suppress error messages
#     -f/--file       Process YAML spec from file
#     -h/--help       Display this message and exit
# Parameters:
#     $@         Names of YAML spec files
# Spec file format:
#     The format is a simple key-value based assignment, but allows arbitrary YAML
#     nesting.  A simple example will illustrate the format:
#     ```yaml
#     key1:
#       key2:
#         ...keyN: value
#     ```
#     This markup will be parsed into the following script by \`pass env\`:
#     ```bash
#     KEY1_KEY2_..._KEYN=value
#     ```
# Examples:
#     eval $(pass env -f -r) # Exports variables specified in $PASS_DIR/.env.yaml,
#                            # forcing reassignment and suppressing error messages

_pass_env_usage() {
    cat <<-USAGE
		pass env
		--------

		`sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# //'`
		USAGE
}

needs() {
    local -a missing=( )
    while [ $# -gt 0 ]; do
        command -v "$1" || missing+=( "$1" )
        shift
    done >/dev/null 2>&1
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Please ensure the following are installed:"
        printf '    - %s\n' "${missing[@]}"
        exit ${#missing[@]}
    fi >&2
}

main() {
    needs gron yq grep awk pass

    local -a cred
    local -i reload=0
    local path pfile yml_addr cred

    eval set -- $(getopt -o "r" -l "reload" -- "$@")
    while [ $# -gt 0 ]; do
        case "$1" in
            -r|--reload) reload=1 ;;
            --) shift; break ;;
            *) echo "Unknown opt: $1" >&2; exit 1 ;;
        esac
        shift
    done

    cat "$@" | yq '.' | gron |
        grep -v "= {}" |
        sed -e 's/^json\.//' -e 's/;$//' |
        awk -v FS=" = " '
            {
                $1=toupper(gensub(/\./,"_","g",$1))
                print
            }' |
        while read -r name path; do
            cred=
            if [ -n "${!name+x}" ] && [ $reload -ne 1 ]; then
                echo "$name is already assigned."
                echo "Pass the -r/--reload flag to overwrite it."
                continue
            fi >&2
            # Remove quotes from `gron`
            path="${path:1:-1}"
            pfile="${path%%:*}"
            yml_addr="${path#*:}"
            read -d '' -r cred < <(pass show "$pfile" |
                if [ "$pfile" = "$yml_addr" ]; then
                head -1
            else
                sed '1d' | yq -r ".${yml_addr//:/.}"
            fi)
            echo "export $name=${cred@Q}"
        done
}

main "$@"
