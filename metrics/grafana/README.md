# Grafana Setup

For each Accelerator branch, navigate to its respective sub-directory:
- [AMD](amd/README.md)
- [Intel Gaudi](gaudi/README.md)
- [NVIDIA](nvidia/README.md)


## Deploying the Grafana operator

For this tutorial we will be using the `openshift-user-workload-monitoring` namespace to configure Grafana and deploy the Dashboard.

Execute the Grafana operator using the [deploy-grafana-operator.yaml](../common-assets/deploy-grafana-operator.yaml).
```bash
oc apply -f ../common-assets/deploy-grafana-operator.yaml

# watch the pods and wait until the grafana ones are running:
oc get pods -nopenshift-user-workload-monitoring -w
NAME                                  READY   STATUS    RESTARTS   AGE
prometheus-operator-79c6cf584-75fpm   2/2     Running   0          20h
prometheus-user-workload-0            6/6     Running   0          9h
prometheus-user-workload-1            6/6     Running   0          9h
thanos-ruler-user-workload-0          4/4     Running   0          9h
thanos-ruler-user-workload-1          4/4     Running   0          9h
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     Pending   0          0s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     Pending   0          0s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     ContainerCreating   0          0s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     ContainerCreating   0          0s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     ContainerCreating   0          1s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   0/1     Running             0          3s
grafana-operator-controller-manager-v5-7df8b7dbbf-lkmhs   1/1     Running             0          10s
```

### Grafana Deployment
Now, we can proceed and create the Grafana deployment to serve our needs:

```bash
oc apply -f ../common-assets/grafana-deployment.yaml
# check if the deployment is ready:
oc get grafana -n openshift-user-workload-monitoring
# if it failed, add -oyaml to the previous command for more detailed messages
```

Now, we need to configure the service account so Grafana can query the `Thanos` endpoint.
To do that, apply the content from [service account role binding](../common-assets/sa-rb.yaml)

This will:
- create the service account `grafana-sa`
  - For newer version, the grafana-sa service account is already created.
- Create the sercret token for the service account
- assign the `cluster-monitoring-view` to the service account just created.

```bash
oc apply -f ../common-assets/sa-rb.yaml
```

Now, let's get the `serviceAccount` token and store in a secret:
```Bash
SECRET_NAME=$(oc -n openshift-user-workload-monitoring describe sa grafana-sa | awk '/Tokens/{ print $2 }')
# echo $SECRET_NAME
# grafana-sa-token-zsx9b
TOKEN=$(oc -n openshift-user-workload-monitoring get secret $SECRET_NAME --template='{{ .data.token | base64decode }}')
# echo $TOKEN
# eyJhbGciOiJSUzI1NiIsI.....
```

With the Token ready, let's store it into a secret so we can use it in the next step:
```bash
oc apply -f - <<EOF
kind: Secret
apiVersion: v1
metadata:
  name: credentials
  namespace: openshift-user-workload-monitoring
stringData:
  PROMETHEUS_TOKEN: '${TOKEN}'
type: Opaque
EOF

# Check if the secret was created and has the token
oc get secret credentials -oyaml -n openshift-user-workload-monitoring
```


Now we need to expose it. By default the service name should be `grafana-service`, confirm with the following command:
```bash
oc get svc -n openshift-user-workload-monitoring | grep grafana
```

Expose it:

```bash
oc -n openshift-user-workload-monitoring create route edge grafana --service=grafana-service --insecure-policy=Redirect
# get the route address:
oc -n openshift-user-workload-monitoring get route grafana -o jsonpath='{.spec.host}'
```

Try to access it using https. If everything went fine you should see the login page, use `admin/admin` to access.


We are now ready to move to the next step, and create one the most important resource, the `Datasource` which holds  
information about from where we will be scraping the metrics, by default we will be using `Thanos` endpoint.
```bash
oc create -f ../common-assets/grafana-ds.yaml
oc -n openshift-user-workload-monitoring get GrafanaDatasource -oyaml
# NAME         NO MATCHING INSTANCES   LAST RESYNC   AGE
# grafana-ds                           84s           84s
```


If you find any issue, please let us know.