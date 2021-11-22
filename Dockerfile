FROM pseudomuto/protoc-gen-doc:1.5.0

ENV GENDOC_OPENAPI_FILE="/out/openapi.yaml"
ENV GENDOC_PROTO_ROOT_DIR="/proto"

ADD gendoc.sh /

ENTRYPOINT [ "/gendoc.sh" ]
