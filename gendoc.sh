#!/bin/bash

set -Eeuo pipefail

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

: "${GENDOC_API_NAME:="API Name"}"
: "${GENDOC_API_VERSION:="1.0.0"}"
: "${GENDOC_PROTO_ROOT_DIR:="proto"}"
: "${GENDOC_OPENAPI_FILE:="openapi.yaml"}"

# shellcheck disable=SC2016
help_awk_script='
function strip_lparen(s) {
    gsub(/)$/, "", s);
    return s;
}
function strip_spaces(s) {
    gsub(/\s*$/, "", s);
    gsub(/^\s*/, "", s);
    return s;
}
BEGIN {
    FS = "##";
}
{
    $1 = strip_spaces($1);
    $1 = strip_lparen($1);
    $2 = strip_spaces($2);
    if (NF > 2) {
        $3 = strip_spaces($3);
        $1=$1 " " $2;
        $2=$3;
    }
    printf "   \033[36m%-30s\033[0m %s\n", $1, $2
}'

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
        --openapi-file)      ## FILE ## OpenAPI output file
            GENDOC_OPENAPI_FILE="$2"
            shift
            shift
            ;;
        --help|*)            ## Display this help
            echo "gendoc -- Generate OpenAPI documentation from Proto files"
            echo ""
            echo "USAGE:"
            echo "   $(basename "$0") [OPTIONS]"
            echo ""
            echo "OPTIONS:"
            grep -E '^\s*--\S+?)\s*?##' "$0" | xargs -L1 | awk "$help_awk_script"
            exit 1
            ;;
    esac
done

echo 'openapi: "3.0.2"
info:
  title: __PLACE_HOLDER_API_NAME
  version: __PLACE_HOLDER_API_VERSION
  description: |
__PLACE_HOLDER_DOCUMENTATION
paths: {}' > "$GENDOC_OPENAPI_FILE"

# shellcheck disable=SC2046
protoc --doc_out="$TEMP_DIR" \
       --doc_opt=markdown,"doc.md" \
       $(find "$GENDOC_PROTO_ROOT_DIR" -name "*.proto")

sed -i -e "s/^/    /g" "$TEMP_DIR/doc.md"
sed -i -e "s/__PLACE_HOLDER_API_NAME/$GENDOC_API_NAME/g" "$GENDOC_OPENAPI_FILE"
sed -i -e "s/__PLACE_HOLDER_API_VERSION/$GENDOC_API_VERSION/g" "$GENDOC_OPENAPI_FILE"
sed -i -e "/__PLACE_HOLDER_DOCUMENTATION/r $TEMP_DIR/doc.md" \
       -e "/__PLACE_HOLDER_DOCUMENTATION/d" "$GENDOC_OPENAPI_FILE"
