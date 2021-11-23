#!/bin/bash

set -Eeo pipefail

temp_dir="$(mktemp -d)"
trap 'rm -rf -- "$temp_dir"' EXIT

: "${GENDOC_API_NAME:="API Name"}"
: "${GENDOC_API_VERSION:="1.0.0"}"
: "${GENDOC_PROTO_ROOT_DIR:="."}"
: "${GENDOC_PROTO_INCLUDE_DIR:=""}"
: "${GENDOC_OPENAPI_FILE:="openapi.yaml"}"

# shellcheck disable=SC2016
help_script='
function strip_option(s, p) {
    gsub(/(\|\*)?\)$/, "", s);
    return s;
}
function strip_spaces(s) {
    gsub(/[ \t]*$/, "", s);
    gsub(/^[ \t]*/, "", s);
    return s;
}
BEGIN {
    FS = "##";
}
{
    $1 = strip_spaces($1);
    $1 = strip_option($1);
    $2 = strip_spaces($2);
    if (NF > 2) {
        $3 = strip_spaces($3);
        $1=$1 " " $2;
        $2=$3;
    }
    printf "   \033[36m%-22s\033[0m %s\n", $1, $2
}'

positional=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --api-name)          ## NAME ## API name
            GENDOC_API_NAME="$2"
            shift
            shift
            ;;
        --api-version)       ## VERSION ## API version
            GENDOC_API_VERSION="$2"
            shift
            shift
            ;;
        --proto-root-dir)    ## DIR ## Protobuf files root directory
            GENDOC_PROTO_ROOT_DIR="$2"
            shift
            shift
            ;;
        --proto-include-dir) ## DIR ## Protobuf include directory
            GENDOC_PROTO_INCLUDE_DIR="$2"
            shift
            shift
            ;;
        --openapi-file)      ## FILE ## OpenAPI output file
            GENDOC_OPENAPI_FILE="$2"
            shift
            shift
            ;;
        --help)              ## Display this help
            echo "gendoc -- Generate OpenAPI documentation from Proto files"
            echo ""
            echo "USAGE:"
            echo "   $(basename "$0") [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            grep -E '^\s*--\S+?\)\s*?##' "$0" | xargs -L1 | awk "$help_script"
            exit 1
            ;;
        *)                   ## Extra arguments for 'protoc'
            positional+=("$1")
            shift
            ;;
    esac
done
set -- "${positional[@]}" # Restore positional parameters

# OpenAPI template
echo 'openapi: "3.0.2"
info:
  title: _PLACE_HOLDER_API_NAME_
  version: _PLACE_HOLDER_API_VERSION_
  description: |
_PLACE_HOLDER_DOCUMENTATION_
paths: {}' > "$GENDOC_OPENAPI_FILE"

# Split list of source directories
IFS=',' read -ra source_dirs <<< "$GENDOC_PROTO_ROOT_DIR"
for i in "${!source_dirs[@]}"; do
    source_dirs[$i]=$(realpath "${source_dirs[$i]}")
done

# Split list of include directories
IFS=',' read -ra include_dirs <<< "$GENDOC_PROTO_INCLUDE_DIR"
for i in "${!include_dirs[@]}"; do
    include_dirs[$i]=$(realpath "${include_dirs[$i]}")
done

# List of excluded directories to 'find' commant
exclude_args=()
for d in "${include_dirs[@]}"; do
    exclude_args+=("-not" "-path" "$d/*")
done

# Build list of sources files
source_files=()
for d in "${source_dirs[@]}"; do
    while IFS= read -rd $'\0' f; do
        source_files+=("$f")
    done < <(find "$d" -name "*.proto" "${exclude_args[@]}" -print0)
done

# Generate Markdown documentation
include_dirs+=("${source_dirs[@]}")
protoc --doc_out="$temp_dir" \
       --doc_opt=markdown,"doc.md" \
       "${include_dirs[@]/#/-I}" \
       "${source_files[@]}" \
       "$@"

# Create OpenAPI file from template and replace place holders
sed -i -e "s/^/    /g" "$temp_dir/doc.md"
sed -i -e "s/_PLACE_HOLDER_API_NAME_/$GENDOC_API_NAME/g" "$GENDOC_OPENAPI_FILE"
sed -i -e "s/_PLACE_HOLDER_API_VERSION_/$GENDOC_API_VERSION/g" "$GENDOC_OPENAPI_FILE"
sed -i -e "/_PLACE_HOLDER_DOCUMENTATION_/r $temp_dir/doc.md" \
       -e "/_PLACE_HOLDER_DOCUMENTATION_/d" "$GENDOC_OPENAPI_FILE"
