# Deploying and Using InferenceService

This guide provides the steps to deploy an InferenceService and make an inference request using the deployed service  
Using the CaiKit Serving Runtime to deploy the `flan-t5-small-caikit` model for simple

## Prerequisites

- Running OpenShift Container Platform (OCP) Cluster 
  - GPU is not needed, as it is a very basic model.
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

Once the InferenceService is deployed and ready, you can make an inference request using `curl`.

1. **Create a request file (`request-example.txt`):**

    ```plaintext
    curl --insecure -X POST https://caikit-3-fspolti.apps.rosa.hannah-kserve.7cma.p3.openshiftapps.com/api/v1/task/text-generation \ 
    -H "Content-Type: application/json" -d '{"model_id":"flan-t5-small-caikit","inputs": "At what temperature does liquid Nitrogen boil?"}'
    ```

2. **Run the request:**

    ```bash
    sh request-example.txt
    ```

This will send a POST request to the deployed InferenceService and return the inference result.
