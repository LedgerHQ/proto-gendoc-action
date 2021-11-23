# Gendoc

## Build Docker image

```bash
docker build -t gendoc .
```

## Generate OpenAPI from Proto files

```bash
docker run --rm -v "$(pwd):/data" --workdir "/data" \
  gendoc --api-name "My API" --api-version "1.0.0" \
    --openapi-file "doc/openapi.yaml" \
    --proto-root-dir "examples/"
```
