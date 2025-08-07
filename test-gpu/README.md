## GPU Test Pod

Minimal pod spec to verify GPU scheduling and drivers.

```bash
oc apply -f gpu-test-pod.yaml
oc logs -f pod/gpu-test-pod
```


