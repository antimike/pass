#!/bin/bash
# "Prefills" a pass entry file with data from an encrypted template

# echo "Not implemented" >&2
# exit 1

if [ -f "$BASH_INCLUDE" ]; then
    source "$BASH_INCLUDE"
else
    echo "Could not find 'include.sh'" >&2
    exit 23
fi

typeset -r PASSROOT="${PASS_DIR:-$HOME/.password-store}"
PASSROOT="${PASSROOT%/}"    # Remove trailing slash
typeset TEMPLATE_FNAME=".template"

_get_template_path() {
    local path="$*"

    while [ -n "$path" ] && [ ! -f "${PASSROOT}/${path}/${TEMPLATE_FNAME}" ];
    do
        path="$(dirname "$path")"
    done
    path="${path}/${TEMPLATE_FNAME}"
    debug_vars path PASSROOT
    local path="${PASSROOT}/${path#/}"
    echo "$path" && [ -f "$path" ]
    return $?
}

_edit_template() {
    local path="$1"
    vipe <${path}
}

main() {
    local -A fields=( )
    local -a comments=( )
    local -a links=( )
    local -a tags=( )
    while [ $# -gt 0 ]; do
        case "$1" in

            # Sub-commands
            new-template)
                shift   # OK if this fails
                _edit_template "$(_get_template_path "$*")"
                ;;

            # Common fields can be abbreviated
            -n)     # Username
                shift && fields["username"]="$1"
                ;;
            -u)     # URL
                shift && fields["url"]="$1"
                ;;
            -H)
                shift && fields["hostname"]="$1"
                ;;
            -c)     # Comments (cumulative)
                shift && comments+=( "$1" )
                ;;
            -t)     # Tags (cumulative)
                shift && tags+=( "$1" )
                ;;
            -e)     # Email
                shift && fields["email"]="$1"
                ;;
            -d)     # Description
                shift && fields["description"]="$1"
                ;;
            -L)     # "Links"
                    # Can represent a reference to any type of related data or
                    # file
                shift && links+=( "$1" )
                ;;

            # Long-form options are interpreted "verbatim"
            --*)
                fields["${1#--}"]="$2" && shift
                ;;
            --)
                shift && break
                ;;
            *)
                break
                ;;
        esac
        shift
    done
    shift $(( OPTIND - 1 )) && OPTIND=1

    debug_vars fields comments links tags

    debug "Params: '$@'"
    _get_template_path "$*"
    return $?

    # for field in "${!fields[@]}"; do
    #     :
    # done


}

main "$@"
