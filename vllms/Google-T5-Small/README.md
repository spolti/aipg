# Deploy Google T5 Small on OpendataHub with Grafana Dashboard for GPU and vLLM metrics

# Requirements:

To follow this example you will need:

* Running OCP Cluster with GPU available
* `oc` or `kubectl` command line tools to interact with the OCP Server
* `Podman` or `Docker` Container Engine

## Required Operators
Deploy ODH in Serverless mode, to do this install these operators in order:

* Red Hat OpenShift Service Mesh (Istio)
* Red Hat OpenShift Serverless
* Authorino (required only if you want to have authentication enabled for inference requests)
* Open Data Hub Operator (at the time of this writing, the version 2.22.0)


Plus, it will require GPU, make sure you have it available in your cluster.

You should have these operators installed:

![Installed Operators](images/operators.png)


## Configuring OpenDataHub environment

As next step, configure the ODH operator by providing two resources:


* The Data Science Cluster Initialization (DSCI)
  * The Operator configuration
* The Data Science Cluster (DSC)
  * The component configuration. For this example we will use the following:
    * Dashboard (optional)
      * For this example, everything will be deploy manually, with no Dashboard enabled.
    * KServe


The DSCI will look like (default configuration):

```yaml
kind: DSCInitialization
apiVersion: dscinitialization.opendatahub.io/v1
metadata:
  labels:
    app.kubernetes.io/created-by: opendatahub-operator
    app.kubernetes.io/instance: default
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: dscinitialization
    app.kubernetes.io/part-of: opendatahub-operator
  name: default-dsci
spec:
  applicationsNamespace: opendatahub
  monitoring:
    managementState: Managed
    namespace: opendatahub
  serviceMesh:
    controlPlane:
      metricsCollection: Istio
      name: data-science-smcp
      namespace: istio-system
    managementState: Managed
  trustedCABundle:
    customCABundle: ''
    managementState: Managed
```

Install it and wait for the installation to finish. Next, proceed with the DSC:

The DSC:

```yaml
kind: DataScienceCluster
apiVersion: datasciencecluster.opendatahub.io/v1
metadata:
  labels:
    app.kubernetes.io/created-by: opendatahub-operator
    app.kubernetes.io/instance: default
    app.kubernetes.io/managed-by: kustomize
    app.kubernetes.io/name: datasciencecluster
    app.kubernetes.io/part-of: opendatahub-operator
  name: default-dsc
spec:
  components:
    codeflare:
      managementState: Removed
    dashboard:
      managementState: Removed
    datasciencepipelines:
      managementState: Removed
    kserve:
      managementState: Managed
      nim:
        managementState: Removed
      serving:
        ingressGateway:
          certificate:
            type: OpenshiftDefaultIngress
        managementState: Managed
        name: knative-serving
    kueue:
      managementState: Removed
    modelmeshserving:
      managementState: Removed
    modelregistry:
      managementState: Removed
      registriesNamespace: odh-model-registries
    ray:
      managementState: Removed
    trainingoperator:
      managementState: Removed
    trustyai:
      managementState: Removed
    workbenches:
      managementState: Removed
```

Install it and wait for it to get ready. Execute the command below to see the installation status:

```bash
oc get pods -n opendatahub --watch
NAME                                        READY   STATUS    RESTARTS   AGE
kserve-controller-manager-b76cf8c5b-rcqcm   1/1     Running   0          28s
odh-dashboard-7b794bb564-k9ks7              2/2     Running   0          68s
odh-dashboard-7b794bb564-txg5v              2/2     Running   0          68s
odh-model-controller-754f494b86-bfm78       1/1     Running   0          69s
```

KServe, Dashboard and odh-model-controller should be in the running state. If you encounter problems, check the logs of the `opendatahub-operator` in the `openshift-operators` namespace.


## Configuring the runtime

For this example, we will use the default runtime for vLLM provided by the ODH Model Controller, available as a template [here](https://github.com/opendatahub-io/odh-model-controller/blob/incubating/config/runtimes/vllm-template.yaml).

Use this command to install the Serving Runtime:

```bash
oc new-project granite
# for nvidia
oc process -n opendatahub -o yaml vllm-cuda-runtime-template | oc apply -f -
```
For AMD:
```bash
oc process -n opendatahub -o yaml  vllm-rocm-runtime-template | oc apply -f -
```


Check if it was installed:

```bash
oc get servingruntimes
NAME           DISABLED   MODELTYPE   CONTAINERS         AGE
vllm-cuda-runtime              vLLM        kserve-container   86s
```


## Preparing the OCI container

As vLLM models tends to be big, we will be using the OCI feature, which consists in a pré-build container image with the Model already in it. It will save a lot of time during the startup time.

### Preparing the OCI container

As first step, make sure the OCI feature is enabled (it should be enabled by default):

```bash
  oc get cm/inferenceservice-config -n opendatahub -oyaml | grep enableModelcar
...
        "enableModelcar": true
```
It will print some other content, but the last line is the important one, that should be `true`.

Now, build the OCI image. This multi-stage build downloads the model into the image. Inspect the [Containerfile](Containerfile).

```
podman build --format=oci --arch x86_64 --squash \
  --build-arg repo_id=google-t5/t5-small \
  --build-arg token=<HUGGINGFACE_TOKEN> \
  -t quay.io/spolti/t5-small:1 .
```

Remember to update the registry to fit your needs.

Then push it to your preferred registry.

**Tip**: If the registry requires auth, configure a pull secret.
Example:
```bash
oc create secret docker-registry quay-pull-secret \
  --docker-server=quay.io \
  --docker-username=<your-quay-username> \
  --docker-password=<your-quay-password> \
  --docker-email=<your-email>

# Link the Secret to Your Service Account
oc secrets link default quay-pull-secret --for=pull 

# Verify the Secret is Linked
oc get serviceaccount default -o yaml
```

> Remember to update the `serviceAccount` name if you use a different one.

#### TODO rework the pieces below to t5 model


## Deploying the InferenceService

Now it is time to deploy the Model and start sending requests to it.

Use [inference-service](inference-service.yaml) to deploy it.

```bash
oc apply -f inference-service.yaml
```

**Tip:** If you used a different image, update the YAML accordingly.

Check the deployment status:
```bash
oc get pods -n granite --watch
NAME                                                      READY   STATUS     RESTARTS   AGE
granite318b-predictor-00001-deployment-66b9d596bf-zsnhx   0/3     Init:0/1   0          2m26s
```
Wait until it gets ready. This might take a while since the model is large.
If the status does not change to `Init:0/1` and stays `Pending`, check events for hints:
```bash
oc get events -n granite
```


Once ready, try to inference it

```bash
ISVC_HOST=$(oc get inferenceservice granite318b -o jsonpath='{.status.url}' -n granite | cut -d "/" -f 3)
curl -s https://$ISVC_HOST/v1/completions \
      -H "Content-Type: application/json" \
      -d '{
          "model": "granite318b",
          "prompt": "What is the IBM granite-3 model?",
          "max_tokens": 200,
          "temperature": 0.8
      }' | jq
```
> Note: If you get `jq: command not found` remove it with the `|` character, or install it.

The response would be something like:
```yaml
{
  "id": "cmpl-852db834-861e-4643-89bf-45a6c6fafb00",
  "object": "text_completion",
  "created": 1738342575,
  "model": "granite318b",
  "choices": [
    {
      "index": 0,
      "text": "\n\nThe IBM granite-3 model is a language model developed by IBM Research. It is designed to understand and generate human-like text based on the input it receives. It is trained on a diverse range of internet text, and it can be used for a variety of natural language processing tasks, such as text summarization, question answering, and dialogue generation. The model is called \"granite-3\" because it is the third version of the IBM Granite series of language models. The previous versions, Granite-1 and Granite-2, were also developed by IBM Research. The IBM granite-3 model is not available for public use, and it is used internally by IBM for research and development purposes.",
      "logprobs": null,
      "finish_reason": "stop",
      "stop_reason": null,
      "prompt_logprobs": null
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "total_tokens": 164,
    "completion_tokens": 154,
    "prompt_tokens_details": null
  }
}
```