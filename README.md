# Gendoc

## Build Docker image

```bash
docker build -t gendoc .
```

## Generate OpenAPI from Proto files

```bash
docker run --rm \
  -v $(pwd)/doc:/out \
  -v $(pwd)/proto:/proto \
  gendoc --api-name "My API" --api-version "1.0.0"
```
