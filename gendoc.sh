#!/bin/bash

set -Eeuo pipefail

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_DIR"' EXIT

: "${GENDOC_API_NAME:="API Name"}"
: "${GENDOC_API_VERSION:="1.0.0"}"
: "${GENDOC_PROTO_ROOT_DIR:="proto"}"
: "${GENDOC_OPENAPI_FILE:="openapi.yaml"}"

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
        *)
            POSITIONAL+=("$1")
            shift
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
