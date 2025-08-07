## Storage Initializer

Configs and notes to fetch models from S3-compatible storage (e.g., MinIO) at pod start.

- `certs/`: Example CA/cert bundle layout for SSL endpoints.
- `spolti-s3-bucket.env`: Example environment variables for local testing.

### Example

```bash
podman run --env-file spolti-s3-bucket.env -it quay.io/spolti/storage:5 \
  s3://modelmesh-example-models/sklearn/mnist-svm.joblib /tmp/model/
```


