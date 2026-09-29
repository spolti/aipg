# Sentiment analysis with KServe (MLServer + transformer)

Deploys a Hugging Face SST-2 DistilBERT ONNX model on KServe using:

- An **MLServer** ServingRuntime (`mlserver-runtime`) that loads the ONNX graph from `/mnt/models`
- An **InferenceService** named `sentiment-analysis` in Standard deployment mode
- A **custom transformer** that tokenizes raw text and maps scores to `negative` / `positive` (with an optional star rating)

Auth is enabled (`security.opendatahub.io/enable-auth: "true"`), and the service is exposed (`networking.kserve.io/visibility: exposed`).

## Contents

- `sentiment-analisys-runtime-and-isvc.yaml`: ServingRuntime and InferenceService in one file (filename keeps the original spelling)

Model artifacts come from Hugging Face:

`hf://optimum/distilbert-base-uncased-finetuned-sst-2-english`

The transformer uses the same tokenizer name, `--sentiment_labels=negative,positive`, `--max_length=128`, ONNX inputs `input_ids,attention_mask`, and output `predict`.

## Prerequisites

- OpenShift cluster with Open Data Hub / OpenShift AI (KServe)
- `oc` CLI
- Permission to create tokens for the `default` ServiceAccount in the target project

## Deploy

```bash
oc new-project test-transformer-keda
oc apply -f sentiment-analisys-runtime-and-isvc.yaml
oc get inferenceservice sentiment-analysis -n test-transformer-keda
```

Wait until the InferenceService is `Ready`. The first start can take a few minutes while the storage initializer pulls the Hugging Face model.

## Send a request

Mint a bearer token, then POST JSON to the OpenShift route. `instances` is a list of raw strings; the transformer tokenizes them before the ONNX predictor.

```bash
TOKEN=$(oc create token default -n test-transformer-keda)
ROUTE_HOST=$(oc get route sentiment-analysis -n test-transformer-keda -o jsonpath='{.spec.host}')

curl -sk -w "\nHTTP_CODE: %{http_code}\n" \
  "https://${ROUTE_HOST}/v1/models/sentiment-analysis:predict" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"instances": ["This movie was great!", "This movie was terrible."]}'
```

Single-sentence payload:

```bash
TOKEN=$(oc create token default -n test-transformer-keda)
ROUTE_HOST=$(oc get route sentiment-analysis -n test-transformer-keda -o jsonpath='{.spec.host}')

curl -sk -w "\nHTTP_CODE: %{http_code}\n" \
  "https://${ROUTE_HOST}/v1/models/sentiment-analysis:predict" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"instances": ["This movie was great"]}'
```
