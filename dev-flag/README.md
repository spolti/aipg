# Opendatahub DevFlag

This directory contains the configuration for the Opendatahub DevFlag. The DevFlag is used to manage the state of various components in the Opendatahub environment allowing the developer to quick test the changes with all  
components needed running, simulating the entire execution flow.

## Configuration

The main configuration file in this directory is `default-dsc.yaml`. This file defines the state of various components in the Opendatahub environment.

## Components

The following components are compatible by the DevFlag:

- **CodeFlare**: Management state is set to `Removed`.
- **KServe**: Management state is set to `Managed`. The `devFlags` section contains manifests for KServe and the ODH Model Controller.
- **TrustyAI**: Management state is set to `Removed`.
- **Ray**: Management state is set to `Removed`.
- **Kueue**: Management state is set to `Removed`.
- **Workbenches**: Management state is set to `Managed`.
- **Dashboard**: Management state is set to `Managed`.
- **ModelMeshServing**: Management state is set to `Removed`.
- **DataSciencePipelines**: Management state is set to `Removed`.

## Usage

To apply the DevFlag configuration, use the following command:

```bash
oc apply -f default-dsc.yaml
```


> Note that, if the DevFlag is `modelmesh-serving` used to override the manifests, make sure that your branch is named as
> `model-mesh` or `modelmeshserving`, there is a bug in the Opendatahub operator that only considers reads the git repository
> is one of these strings are present in the URI.