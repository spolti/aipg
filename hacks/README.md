## Hacks

Ad-hoc utilities and snippets that support experiments in this repo.

- `docker-account.md`: Notes for handling container registry credentials.
- `minio-job.yaml`: Kubernetes Job to pre-populate a MinIO bucket with a sample sklearn model.

### Usage

- To run the MinIO init Job, ensure a MinIO service is reachable at `minio-service.kserve:9000`, then:

```bash
oc apply -f minio-job.yaml
```

Delete the Job when finished:

```bash
oc delete job minio-init || true
```


