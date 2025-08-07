# Raw Deployment


## Deploy model using huggingfaces protocol.

Create a namespace:
```bash
oc new-project hugging
```

Now we need to apply the `vllm` template in order to deploy models from Hugging Face:
```bash
# apply with the default values
oc process -n opendatahub -o yaml vllm-cuda-runtime-template | oc apply -f -
```

Deploy the following InferenceService
```yaml
oc apply -f - <<EOF
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  name: huggingface-t5
spec:
  deploymentMode: RawDeployment
  predictor:
    model:
      modelFormat:
        name: vLLM
      args:
        - --model_name=t5
        - --model_id=google/t5-small-lm-adapt
        - --backend=huggingface
    storageUri: "hf://google/t5-small-lm-adapt"
EOF
```

```yaml
oc apply -f - <<EOF
apiVersion: "serving.kserve.io/v1beta1"
kind: "InferenceService"
metadata:
  name: "huggingface-t5"
  annotations:
    serving.kserve.io/deploymentMode: "RawDeployment"
#     serving.kserve.io/storage-initializer-uid: "1000760000"
spec:
  predictor:
    imagePullSecrets:
    - name: dockerhub-pull-secret
    model:
      modelFormat:
        name: vLLM
      storageUri: "hf://google/t5-small-lm-adapt"
      env:
        - name: VLLM_DEVICE
          value: "cpu"
        - name: MODEL_NAME
          value: "google-t5-small"
        # - name: HUGGINGFACE_HUB_CACHE
        #   value: /mnt/models
        # - name: HF_HOME
        #   value: /tmp/hf_home
    podSpec:
      containers:
        - name: storage-initializer
          env:
            - name: HF_HOME
              value: "/tmp/hf_home"
EOF
```