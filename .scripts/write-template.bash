#!/bin/bash
# Writes a simple YAML-esque config file with the passed options as keys /
# values

# NOTE: This MUST BE removed in order to avoid namespace collisions with `pass`
# itself!!
# if [ -f "$BASH_INCLUDE" ]; then
#     source "$BASH_INCLUDE"
# else
#     echo "Could not find 'include.sh'" >&2
#     exit 23
# fi

typeset -rA _TEMPLATE_FIELDNAMES=(
    [-n]="username"
    [-u]="url"
    [-H]="hostname"
    [-e]="email"
    [-d]="description"
)

typeset -A _FIELDS=( )
typeset outfile=

write_template_usage() {
    _print_assoc_array() {
        local -n assoc_arr="$1"
        paste \
            <(printf '%s\n' "${!assoc_arr[@]}") \
            <(printf '%s\n' "${assoc_arr[@]}") |
            sed 's/^/    /'
    }
    local -A opts=(
        [-o]="Specify output file (optional)"
        [-h]="Display this message and exit"
    )
    cat <<-USAGE
	
	write-template.bash
	===================
	
	Summary
	-------
	Outputs a simple colon-delimited key-value template based on parameters provided
	to the script.  Parameters of the form '--foo' with accompanying argument 'bar'
	will be interpreted as a key-value pair 'foo: bar'.  Certain ommonly-used fields
	may be abbreviated with a shorter form, e.g. '-n' --> '--username' (see
	"Accepted abbreviations" for details).
	
	Output is written to stdout.  If an optional output file is provided, output
	will be redirected to it via \`tee\`.
	
	Options
	-------
	`_print_assoc_array opts`
	
	Accepted abbreviations
	----------------------
	`_print_assoc_array _TEMPLATE_FIELDNAMES`
	
	USAGE
}

main() {
    while [ $# -gt 0 ]; do
        unset field
        case "$1" in
            -h)
                write_template_usage && exit 0 || exit -1
                ;;
            -o)
                outfile="$2"
                ;;
            --*)
                _FIELDS["${1#--}"]="$2"
                ;;
            --)
                shift && break
                ;;
            -*)
                if [[ -n "${field:=${_TEMPLATE_FIELDNAMES["$1"]}}" ]]; then
                    _FIELDS["$field"]="$2"
                else
                    echo "Unknown option '$1' encountered" >&2
                    exit 3
                fi
                ;;
            *)
                break
                ;;
        esac
        shift 2
    done

    outfile="${1:-${outfile:-/dev/null}}"
    # debug_vars outfile _FIELDS

    for key in "${!_FIELDS[@]}"; do
        echo "${key}: ${_FIELDS[$key]}"
    done | tee -a $outfile
}

main "$@"
