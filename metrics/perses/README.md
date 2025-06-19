# Perses example

This example aims to create a the Metrics Dashboards defined in this repository for Grafana using Perses, which is a dashboard tool to display observability data.

This example will demonstrate how to install and configure it on OpenShift Cluster.

- It can be installed by installing the Cluster Observability Operator (COO), available in the Operator Hub
![COO-perator](assets/images/coo-poerator.png)


Once the operator is ready, the first step is:

- create the monitoring namespace
```bash
oc new-project monitoring
```

- Create the Perses Instance
```bash
oc create -f assets/perses-instance.yaml
```

- Create a route to expose the Perses deployment:
```bash
# the perses service is already created by the COO
oc expose service perses
# then
HOST=$(oc get routes -n monitoring -o jsonpath='{.items[*].spec.host}')
```

- log in with `percli` - this step is not mandatory, it is useful if you need to migrate a grafana dashboard
```
# use the exposed route from the previous command:
percli login http://$HOST
```


## Migrating Grafana Dashboards

For Nvidia we have a grafa dashboard that will be used to configure the Perses dashboard.
To proceed, install `percli`, more information [here](https://perses.dev/perses/docs/cli/)

- Convert from Grafana to Perses
```bash
percli 
```