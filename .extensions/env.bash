#!/bin/bash
# Assigns credential stored by \`pass\` to environment variable
# Input:
#   - Name of environment variable
#       - Location of desired credential should be assigned to this variable
#       prior to calling this function
#       - Format: [path/to/cred/file]:[YAML property names]
#       - If assigned value isn't found by \`pass\`, it's assumed that the
#       correct password is already assigned
# Examples:
#   export TEST=personal/test:prop
#   passenv TEST
#   # If the line "prop: val" is included in the file $PASS_DIR/personal/test,
#   # then this will assign the string "val" to variable TEST

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
    local path pfile yml_addr
    cat "$@" | yq '.' | gron |
        grep -v "= {}" |
        sed -e 's/^json\.//' -e 's/;$//' |
        awk -v FS=" = " '
            {
                $1=toupper(gensub(/\./,"_","g",$1))
                print
            }' |
        while read -r name path; do
            var=""
            echo "Processing $name --> $path" >&2
            # Remove quotes from `gron`
            path="${path:1:-1}"
            pfile="${path%%:*}"
            yml_addr="${path#*:}"
            read -d '' -r var < <(pass show "$pfile" |
                if [ "$pfile" = "$yml_addr" ]; then
                echo "Extracting password from pfile $pfile..." >&2
                head -1
            else
                echo "Extracting YAML $yml_addr from pfile $pfile..." >&2
                sed '1d' | yq -r ".${yml_addr//:/.}"
                fi)
            echo "Assigning $name=${var}" >&2
            export "$name"="${var}"
        done
}

main "$@"
