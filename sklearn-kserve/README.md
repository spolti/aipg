## sklearn + KServe examples

Artifacts to deploy sklearn models with KServe.

- `serving-runtime-sklearn.yaml`: Example ServingRuntime.
- `sklearn-example-isvc*.yaml`: Multiple InferenceService variants (PVCs, init containers, hostPath).
- `payload.json`, `example-request.txt`: Example request bodies.

### Quick start

```bash
oc apply -f serving-runtime-sklearn.yaml
oc apply -f sklearn-example-isvc.yaml
```

Send a request:

```bash
HOST=$(oc get inferenceservice sklearn -o jsonpath='{.status.url}' | cut -d/ -f3)
curl -s https://$HOST/v1/models/sklearn:predict -H 'content-type: application/json' -d @payload.json
```


