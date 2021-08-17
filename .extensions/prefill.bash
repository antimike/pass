#!/bin/bash
# "Prefills" a pass entry file with data from an encrypted template

# NOTE: This MUST BE removed in order to avoid namespace collisions with `pass`
# itself!!
# if [ -f "$BASH_INCLUDE" ]; then
#     source "$BASH_INCLUDE"
# else
#     echo "Could not find 'include.sh'" >&2
#     exit 23
# fi

typeset _EDITOR="${EDITOR:-vi}"
typeset _TEMPLATE=
typeset _TEMPLATE_NAME=".template"
typeset _TEMPLATE_WRITER="${PREFIX}/.scripts/write-template.bash"
typeset _TEMPLATE_JOINER="${PREFIX}/.scripts/merge-templates.bash"
typeset _COMMIT_MSG_FORMAT=\
    "%s password file for %s using template %s and editor ${_EDITOR}"
typeset _ACTION="generate"

if [ ! -x "${_TEMPLATE_WRITER}" ] || [ ! -x "${_TEMPLATE_JOINER}" ]; then
    die "Cannot find template read / write scripts"
fi

pass_get_template_path() {
    local path="$(pass_get_path "$1")"

    while [ -n "$path" ] && [ ! -f "${PASSROOT}/${path}/${TEMPLATE_FNAME}" ];
    do
        path="$(dirname "$path")"
    done
    path="${path}/${TEMPLATE_FNAME}"
    debug_vars path PASSROOT
    path="${PASSROOT}/${path#/}"
    echo "$path" && [ -f "$path" ]
    return $?
}

main() {
    local -A template_params=( )
    local -a comments=( )
    local -a links=( )
    local -a tags=( )
    local -i generate=1
    while [ $# -gt 0 ]; do
        case "$1" in
            -G)     # Do not generate password
                generate=0
                ;;
            -c)     # Comments (cumulative)
                comments+=( "$2" )
                ;;
            -t)     # Tags (cumulative)
                tags+=( "$2" )
                ;;
            -L)     # "Links"
                    # Can represent a reference to any type of related data or
                    # file
                links+=( "$2" )
                ;;
            --)
                shift && break
                ;;
            -*)
                template_params+=( "$1" "$2" )
                ;;
            *)
                break
                ;;
        esac
        shift 2
    done

    local rel_path="$1"
    local fpath="$(pass_get_path "$rel_path")"
    local dir="$(dirname "$fpath")"
    while [[ ! -r "${dir}/${_TEMPLATE_NAME}"  ]] &&
        find "$PREFIX" -type d -name "${dir%/}" &>/dev/null
    do
        dir="$(dirname "$dir")"
    done
    _TEMPLATE="${dir}/${_TEMPLATE_NAME}"
    find "$PREFIX" -type f -path "${_TEMPLATE}" ||
        die "Could not locate a suitable template"

    
    # while [ ! -r "$dir/" ]

    # template="$(pass_get_template_path "$*")" ||
    #     die "No template found!"

    return $?
}

main "$@"

pass_get_tmpfile() {
    # Note that a `trap`-handler is set in the `pass` main script to delete the
    # secure tmpdir, so no further handling is required either here or by the
    # caller
    local seed="$1"
    tmpdir      #Defines $SECURE_TMPDIR
    echo "$(mktemp -u "$SECURE_TMPDIR/XXXXXX")-${seed//\//-}.txt"
}

pass_get_path() {
    path="${1%/}"
    check_sneaky_paths "$path"
    mkdir -p -v "$PREFIX/$(dirname -- "$path")"
    set_gpg_recipients "$(dirname -- "$path")"
    echo "$PREFIX/$path"
    set_git "$PREFIX/$path"     # Not clear what this one does...
                                # TODO: Read the source carefully
    return $?
}

pass_edit() {
    local source="$1"
    local dest="$2"
    if ! [[ -r "$source" && ! -e "$dest" || "$dest" = "$source" ]]; then
        die "Refusing to overwrite existing file '${dest}'"
    fi
    local tmpf="$(pass_get_tmpfile)"
    pass_decrypt "$source" >"$tmpf" || die "Could not decrypt '$source'"
    ${EDITOR:-vi} "$tmpf"
    pass_encrypt "$tmpf" "$dest"
    return $?
}

# TODO: Add namespace checks using `declare` at beginning of script
pass_decrypt() {
    local file="$1"
    $GPG -d "${GPG_OPTS[@]}" "$file"
    return $?
}

pass_encrypt() {
    local infile="$1"
    local outfile="$2"
    while ! $GPG -e "${GPG_RECIPIENT_ARGS[@]}" -o "$1" "${GPG_OPTS[@]}" \
        "$file";
    do
        yesno "GPG encryption failed.  Would you like to try again?"
    done
    return $?
}

pass_commit() {
    local file="$1"
    local format="$2"
    shift 2
    git_add_file "$file" "$(printf "$format" "$@")"
}
