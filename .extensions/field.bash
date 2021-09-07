#!/bin/bash
# Gets a named field from a password-file

_field_usage() {
    cat <<-USAGE
		
		SUMMARY:
		    Prints the value associated with a key-value pair stored in a passfile.
		
		USAGE:
		    pass field [<show-opts>] \$FIELD_NAME [<show-opts>] \$PASS_FILE
		
		OPTS:
		    All options to \`pass show\` may be passed either directly to \`pass field\`
		    or following the first positional argument (i.e., the field name).
		
		USAGE
}

main() {
    trap '_field_usage; exit 1' ERR
    local -a opts=( )
    while true; do
        case "$1" in
            -h|--help) _field_usage; exit 0 ;;
            -*) opts+=( "$1" ); shift ;;
            *) break ;;
        esac
    done
    local -r field="$1" && shift || exit 1
    pass show "${opts[@]}" "$@" | 
        awk -v FS="[[:space:]]*[:=][[:space:]]*" -v key="$field" '
            tolower($1) == tolower(key) {print $2;}
        '
}

main "$@"
