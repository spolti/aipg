# Opendatahub DevFlag

This directory contains configuration for the OpenDataHub DevFlag. It lets you quickly enable components for end-to-end testing.

## Configuration

The main configuration file is `default-dsc.yaml`. It defines the state of various ODH components.

## Components

The following components are configured by the DevFlag:

- **CodeFlare**: Management state is set to `Removed`.
- **KServe**: Management state is set to `Managed`. The `devFlags` section contains manifests for KServe and the ODH Model Controller.
- **TrustyAI**: Management state is set to `Removed`.
- **Ray**: Management state is set to `Removed`.
- **Kueue**: Management state is set to `Removed`.
- **Workbenches**: Management state is set to `Managed`
- **Dashboard**: Management state is set to `Managed`.
- **ModelMeshServing**: Management state is set to `Removed`.
- **DataSciencePipelines**: Management state is set to `Removed`.

## Usage

To apply the DevFlag configuration:

```bash
oc apply -f default-dsc.yaml
```


> Note: If the DevFlag `modelmesh-serving` is used to override manifests, ensure your branch name contains `model-mesh` or `modelmeshserving`. There's a known ODH operator issue that only matches these substrings in the Git URL.