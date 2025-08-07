## AI Playground

A collection of practical examples for Red Hat OpenShift AI / Open Data Hub (ODH): model serving with KServe and ModelMesh, storage helpers, metrics dashboards, and GPU testing.

> Note: This is not an official repository. If you find an issue or misleading information, please open one.

### Repository layout

- `caikit/`: InferenceService example using the Caikit Serving Runtime
- `hacks/`: Ad‑hoc utilities (e.g., MinIO pre-population Job)
- `metrics/`: Grafana and Perses setup and dashboards
- `minio/`: MinIO manifests and example models for local testing
- `modelmesh/openvino/`: OpenVINO ServingRuntime + MNIST example
- `persistent-volume/`: PV/PVC examples for different access modes
- `rawDeployment/`: KServe RawDeployment examples (e.g., vLLM with Hugging Face backend)
- `rhoai-resources/`: ODH/RHOAI cluster resources (DSC/DevFlag)
- `sklearn-kserve/`: sklearn ServingRuntime and InferenceService examples
- `storage-initializer/`: S3/MinIO storage initializer notes and cert layout
- `test-gpu/`: Minimal pod to validate GPU scheduling and drivers
- `torchserver/`: TorchServe examples and payloads
- `vllms/`: vLLM examples (Granite, Google T5 Small, Llama)

### Prerequisites

- Access to an OpenShift cluster
- `oc` CLI
- Optional: GPU nodes for GPU-backed examples

### Getting started

Pick a directory based on your interest (e.g., `sklearn-kserve/`, `vllms/Granite-vLLM/`, `modelmesh/openvino/`) and follow its README.
