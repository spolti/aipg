# Deploy mnist on OpenVino Serving Runtime

```bash
oc new-project mnist
```

Before moving forward, install the MinIO to serve the model, it can be quickly done by the following command:
```bash
oc apply -f ../minio/minio.yaml
```


Deploy the Serving Runtime
```bash
oc apply -f openvino-serving-runtime.yaml
```

Deploy the model
```bash
oc apply -f mnist-isvc.yaml
```

To get the URL and path:
```bash
oc get route example-onnx-mnist -ojsonpath='{.spec.host}'
oc get route example-onnx-mnist  -ojsonpath='{.spec.path}'
```


Test your model with:
```bash
X=30 ./run-request.sh <model_url>
```

