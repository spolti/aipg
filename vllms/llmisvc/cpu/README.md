# CPU LLMInferenceService (facebook/opt-125m)

Single-node vLLM on CPU. No GPU. No Gateway, HTTPRoute, or OpenShift Route: traffic stays in-cluster.

## Deploy

```bash
oc new-project provider-llm
oc apply -f llmisvc-cpu-example.yaml
oc get llminferenceservice facebook-opt-125m-single -w
oc get pod -l app.kubernetes.io/name=facebook-opt-125m-single -w
```

Wait until the workload pod is `Running`. The first start pulls the Hugging Face model and can take several minutes.

The ClusterIP Service is `facebook-opt-125m-single-kserve-workload-svc` on port `8000`.

## Call the model

Port-forward the workload Service, then use the OpenAI-compatible API on localhost. Paths are `/v1/...` (no `/{namespace}/{name}` prefix).

```bash
oc port-forward svc/facebook-opt-125m-single-kserve-workload-svc 8000:8000
```

In another terminal:

Completions:

```bash
curl -s http://127.0.0.1:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "prompt": "Hello, my name is",
    "max_tokens": 16
  }'
```

Chat (uses the ConfigMap chat template):

```bash
curl -s http://127.0.0.1:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "facebook/opt-125m",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 16
  }'
```

From another pod in the same project, skip port-forward and use the Service DNS:

```bash
curl -s http://facebook-opt-125m-single-kserve-workload-svc:8000/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"facebook/opt-125m","prompt":"Hello, my name is","max_tokens":16}'
```
