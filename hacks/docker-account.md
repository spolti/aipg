# Creating Docker Pull Credentials in Kubernetes Using Local Authenticated User

This guide explains how to create Docker pull credentials (image pull secret) in a Kubernetes cluster using your locally authenticated Docker user. This is useful for pulling images from private registries.

---

## Step 1: Authenticate Locally with Docker

First, ensure you are logged in to your Docker registry from your local machine.

For Docker Hub, you can log in interactively:

```sh
podman login <registry>
```


## Step 2: Create a Kubernetes Secret from Your Local Docker Credentials

Kubernetes can use your local Docker credentials to create a secret of type `kubernetes.io/dockerconfigjson`.

Run the following command (replace `<secret-name>` and `<namespace>` as needed):

```sh
kubectl create secret generic <secret-name> \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  -n <namespace>
```

- `<secret-name>`: Name for your secret, e.g., `regcred`
- `<namespace>`: Namespace where your workloads will run, e.g., `default`

**Example:**

```sh
kubectl create secret generic regcred \
  --from-file=.dockerconfigjson=$HOME/.docker/config.json \
  --type=kubernetes.io/dockerconfigjson \
  -n default
```

---

## Step 3: Use the Secret in Your Kubernetes Workloads (Pod Annotation)

To allow your pods to use this secret when pulling images, reference it in your Pod or Deployment YAML under `imagePullSecrets`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-private-image-pod
spec:
  containers:
    - name: my-container
      image: <your-private-image>
  imagePullSecrets:
    - name: regcred
```

- Replace `<your-private-image>` with the full image path (e.g., `docker.io/youruser/yourimage:tag`).

For Deployments, add `imagePullSecrets` at the same level as `containers` under `spec.template.spec`.

---

## Step 4: Set the Image Pull Secret as Default for the Namespace (Recommended)

Instead of annotating every Pod or Deployment, you can set the image pull secret as the default for the entire namespace by patching the default service account. This way, all pods in the namespace will use the secret unless they specify their own `imagePullSecrets`.

### Add the Image Pull Secret to the Default Service Account

Assuming your secret is named `regcred` and your namespace is `default`:

```sh
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}' \
  -n kserve
```

- Replace `default` after `-n` with your target namespace if needed.
- If you want to add to an existing list of secrets, you may need to merge rather than overwrite.

### Verify

Check that the service account now references your secret:

```sh
kubectl get serviceaccount default -n default -o yaml
```

You should see:

```yaml
imagePullSecrets:
  - name: regcred
```

### Effect

Now, any Pod in that namespace that does **not** specify its own `imagePullSecrets` will automatically use the secret(s) listed in the service account. If a Pod does specify its own `imagePullSecrets`, those will override the service account's setting.

---

## Step 5: Verify the Secret

You can check that the secret was created:

```sh
kubectl get secret <secret-name> -n <namespace>
```

And describe it:

```sh
kubectl describe secret <secret-name> -n <namespace>
```

---

## Summary Table

| Step | Command/Action | Description |
|------|----------------|-------------|
| 1    | `docker login` | Authenticate locally with your registry |
| 2    | `kubectl create secret generic ...` | Create Kubernetes secret from Docker config |
| 3    | Reference secret in YAML | Allow pods to use the secret for image pulls (per pod/deployment) |
| 4    | `kubectl patch serviceaccount ...` | Set default image pull secret for the namespace (recommended) |
| 5    | `kubectl get/describe secret ...` | Verify secret creation |

---


oc get secret -n openshift-config pull-secret -o template='{{index .data ".dockerconfigjson"}}' | base64 --decode | jq > image-pull-secret.json
# add docker auth 
oc set data secret -n openshift-config pull-secret --from-file=.dockerconfigjson=image-pull-secret.json