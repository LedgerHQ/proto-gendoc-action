# proto-gendoc

This tool generates a Markdown documentation from Protobuf files using the
[`protoc-gen-doc`](https://github.com/pseudomuto/protoc-gen-doc) plugin and
inserts it in an OpenAPI file.

The main goal of this tools is to be able to easily publish Protobuf
documentation to services like Redocly.

## Action usage

```yaml
- uses: LedgerHQ/proto-gendoc-action@v1
  with:
    # Name of the API.
    api-name: ''

    # Version of the API. For example, 1.0.0
    api-version: ''

    # Root directory of the Protobuf files. For example, proto/
    proto-root-dir: ''

    # Directory of included files. For example, _deps/googleapis
    # It can contain a list of comma-separated directories.
    proto-include-dir: ''
```

If your Protofiles have external dependencies, like `googleapis`, one option is
to clone the dependency:

```yaml
- uses: actions/checkout@v2
  with:
    repository: googleapis/googleapis
    path: _deps/googleapis
```

And set the `proto-include-dir` variable:

```yaml
- uses: LedgerHQ/proto-gendoc-action@v1
  with:
    # ...
    proto-include-dir: _deps/googleapis
```

## Docker usage

This tool can also be used locally using Docker.

### Build Docker image

```bash
docker build -t gendoc .
```

### Generate OpenAPI from Proto files

```bash
docker run --rm -v "$(pwd):/data" --workdir "/data" \
  gendoc --api-name "My API" --api-version "1.0.0" \
    --openapi-file "doc/openapi.yaml" \
    --proto-root-dir "examples/"
```
