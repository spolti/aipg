# Deploying and Using InferenceService

This guide shows how to deploy an InferenceService and make a request using the Caikit Serving Runtime with the `flan-t5-small-caikit` model.

## Prerequisites

- Running OpenShift Container Platform (OCP) cluster
  - GPU is not needed for this model
- `oc` or `kubectl` command line tools to interact with the OCP Server
- `Podman` or `Docker` Container Engine

## Deploying the InferenceService

1. **Create a new project:**

    ```bash
    oc new-project caikit
    ```

3. **Apply the Serving Runtime configuration:**

    ```bash
    oc apply -f serving-runtime.yaml
    ```

2. **Apply the InferenceService configuration:**

    ```bash
    oc apply -f isvc.yaml
    ```

3. **Check if the InferenceService is ready:**

    ```bash
    oc get inferenceservice caikit-tgis-isvc
    ```

## Making an Inference Request

Once the InferenceService is ready, you can make an inference request using `curl`.

1. **Create a request file (`request-example.txt`):**

    ```plaintext
    curl --insecure -X POST https://caikit-3-fspolti.apps.rosa.hannah-kserve.7cma.p3.openshiftapps.com/api/v1/task/text-generation \ 
    -H "Content-Type: application/json" -d '{"model_id":"flan-t5-small-caikit","inputs": "At what temperature does liquid Nitrogen boil?"}'
    ```

2. **Run the request:**

    ```bash
    sh request-example.txt
    ```

This sends a POST request to the deployed InferenceService and returns the inference result.
