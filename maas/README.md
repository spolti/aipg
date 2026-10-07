# Multi-tenant setup

-- [source](https://github.com/opendatahub-io/models-as-a-service/blob/e2790eb2a0219412dd5a8d9d9994bc12f0234591/docs/content/install/multi-tenant-setup.md)

## Where things live

| What | Where | Who creates it |
|---|---|---|
| AITenant CR | `ai-tenants` | you |
| Tenant namespace | `ai-tenant-red-team` | maas-controller |
| Gateway + Route | `openshift-ingress` | you |
| `maas-api-<tenant>` | `odh-ai-gateway-infra` | maas-controller |
| LLMInferenceService | e.g. `provider-llm` | you |

The cluster **default tenant** is the exception: `AITenant/models-as-a-service` uses namespace `models-as-a-service` (not `ai-tenant-*`) and Gateway `maas-default-gateway`. Extra tenants such as `red-team` each need their own Gateway; maas-controller only binds to it.

## Namespaces

### `ai-tenants`

Infrastructure namespace for **`AITenant` CRs only**. Cluster-admin (or the controller bootstrap) creates `AITenant` objects here; the admission webhook rejects them in any other namespace. This is not where models, Gateways, or `maas-api` run.

### `ai-tenant-${TENANT_NAME}`

Created by **maas-controller** when you apply an extra `AITenant` (for `red-team` that is `ai-tenant-red-team`). It is a **config namespace**, not a workload namespace:

- `MaasTenantConfig` (always named `default-tenant` — a singleton **per namespace**, not the cluster default tenant)
- `MaaSAuthPolicy` and `MaaSSubscription` once you apply them
- tenant-admin `Role` (controller); `RoleBinding` is yours

There are **no pods**. `oc get all` prints `No resources found` even when the tenant is Ready; CRDs are not listed. Use:

```bash
oc get maastenantconfig,maasauthpolicy,maassubscription,role,rolebinding -n ai-tenant-${TENANT_NAME}
```

Deleting the `AITenant` does not delete this namespace.

### `odh-ai-gateway-infra`

Shared **infrastructure** namespace for ODH when `infra-namespace=AUTO` (controller in `opendatahub` → `odh-ai-gateway-infra`; RHOAI uses `redhat-ai-gateway-infra`). Holds:

- `maas-api-${TENANT_NAME}` Deployment (e.g. `maas-api-red-team`)
- Secret `maas-db-config` with key `DB_CONNECTION_URL` (Postgres; one Secret for the platform, not per tenant)

On ROSA, creating extra namespaces can be restricted; this one is created by the ODH/AI Gateway operator, not by the tenant YAML in this folder.

Related (you create, not maas-controller): `openshift-ingress` (Gateway, Route, TLS Secrets) and the model project (e.g. `provider-llm`).

## ROSA and TLS certificates

Gateway API `certificateRefs` only **points at** a Secret in `openshift-ingress`. Nothing in MaaS issues the listener cert. Upstream docs hardcode `CERT_NAME=router-certs-default` (Ingress Operator self-signed `*.apps` wildcard). **ROSA does not create that name.**

ROSA/OSD sets `IngressController` `spec.defaultCertificate` to a custom ACME/Let’s Encrypt bundle, usually:

`oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.defaultCertificate.name}'`

That Secret is often **`Opaque`**, named like `{hash}-primary-cert-bundle-secret`. Copy it to `kubernetes.io/tls` as `${CERT_NAME}` (`red-team-gateway-tls`) so Istio will accept it:

```bash
SRC=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.defaultCertificate.name}')
NS=openshift-ingress
oc extract secret/"$SRC" -n "$NS" --to=/tmp/rosa-ingress-cert --confirm
oc create secret tls "${CERT_NAME}" -n "$NS" \
  --cert=/tmp/rosa-ingress-cert/tls.crt \
  --key=/tmp/rosa-ingress-cert/tls.key
```

If `oc extract` writes other filenames, pass those to `--cert` / `--key`. Do **not** use `data-science-gateway-service-tls` or `default-ingress-cert` (wrong identity). Do **not** set `serving-cert-secret-name` to `${CERT_NAME}` (service CA would overwrite the wildcard with a `*.svc.cluster.local` cert).

`*.apps.<cluster>` DNS is owned by the **OpenShift router**, not by a Gateway LoadBalancer. On ROSA, set the Gateway Service to **ClusterIP** (`gateway-options-configmap.yaml`) and create **`route.yaml`** (passthrough) if a Route was not auto-provisioned. Do not CNAME the apps hostname to an AWS ELB. `authorino-tls-bootstrap` is Envoy → Authorino only; it does not mint the listener Secret.

## Role of each piece (so far)

| Piece | Role |
|---|---|
| `GatewayClass` `openshift-default` | Turns on OpenShift Gateway API. The Ingress Operator installs Istio and programs `Gateway` objects. Without this, Gateways stay `Waiting for controller`. |
| `gateway-options-configmap.yaml` | Istio `parametersRef` for the Gateway Service (ClusterIP on ROSA so you are not given a public ELB). Do **not** set `serving-cert-secret-name` to the same Secret as the HTTPS listener cert. |
| TLS Secret `${CERT_NAME}` (`red-team-gateway-tls`) | Cert Envoy presents on the Gateway HTTPS listener. Gateway API only **references** a Secret; it does not issue one. On ROSA copy the ingress `…-primary-cert-bundle-secret` into a `kubernetes.io/tls` Secret (docs assume `router-certs-default`, which ROSA does not create). |
| `gateway.yaml` | Per-tenant Gateway. Hostname `red-team-maas.<apps-domain>`, `allowedRoutes` only for namespaces labeled `maas.opendatahub.io/gateway-access-red-team`. Annotations `opendatahub.io/managed: "false"` (annotation, not label) and `authorino-tls-bootstrap` (Envoy → Authorino TLS, **not** the listener cert). |
| `route.yaml` | OpenShift Route so `*.apps` DNS (ROSA router) reaches the Gateway Service. Passthrough: router does not terminate TLS; Envoy uses `${CERT_NAME}`. Needed on ROSA when the Route is not auto-created. |
| `maas-db-config` in `odh-ai-gateway-infra` | Secret with key `DB_CONNECTION_URL`. maas-api will not start without Postgres. |
| `aitenant.yaml` | Declares tenant `red-team` and `spec.gateway.name: red-team`. Controller creates `ai-tenant-red-team`, `MaasTenantConfig/default-tenant`, `maas-api-red-team`, gateway AuthPolicy, Roles. Does **not** create the Gateway. |
| Authorino (Kuadrant / Connectivity Link) | Authz in front of the Gateway. Operator install is not enough; an Authorino instance with TLS must exist. |
| `maasmodelref.yaml` | Registers an LLMInferenceService as a MaaS model. Apply in the **model** namespace (`provider-llm`). |
| `maasauthpolicy.yaml` | Who may call that model. Apply in **`ai-tenant-red-team`**, not `models-as-a-service`. `modelRefs.name` is the MaaSModelRef name. |
| `maassubscription.yaml` | Quota / token rate limits; API keys bind to this. Same namespace rules as AuthPolicy. |
| `rolebinding.yaml` | Controller creates Roles only. Bind users/groups to `aitenant-red-team-tenant-admin` if they need to manage tenant CRs. |
| `kserve-gateway.yaml` | Cluster KServe inference Gateway (`openshift-ai-inference`). **Not** the MaaS per-tenant Gateway. |

!!! Before Begin, you need to install the database or provide your own connection url
```bash
# from maas repo:
NAMESPACE=opendatahub ./setup-database.sh
```

The Secret must end up in `odh-ai-gateway-infra` as `maas-db-config` (key `DB_CONNECTION_URL`) for this ODH layout.

```
TENANT_NAME="red-team"
CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')
GATEWAY_HOSTNAME="${TENANT_NAME}-maas.${CLUSTER_DOMAIN}"
GATEWAY_NAMESPACE="openshift-ingress"
CERT_NAME="${TENANT_NAME}-gateway-tls"
GATEWAY_ACCESS_LABEL="maas.opendatahub.io/gateway-access-${TENANT_NAME}"
GATEWAY_OPTIONS_CONFIGMAP=${TENANT_NAME}-gateway-options
GATEWAY_SERVICE_NAME="${TENANT_NAME}-openshift-default"
```

Apply ConfigMap
```
envsubst < gateway-options-configmap.yaml | oc apply -f -
```

Apply The Tenant Gateway
```bash
# On ROSA be sure to use the correct certificata name: oc get secret -n openshift-ingress | grep -i cert
# usually the first one with random characters in the name
SRC=<VALUE>-primary-cert-bundle-secret
NS=openshift-ingress
oc extract secret/"$SRC" -n "$NS" --to=/tmp/rosa-ingress-cert --confirm
oc create secret tls red-team-gateway-tls \
  -n "$NS" \
  --cert=/tmp/rosa-ingress-cert/tls.crt \
  --key=/tmp/rosa-ingress-cert/tls.key

envsubst < gateway.yaml | oc apply -f -
```


If there is no `default gateway` class, create one:

```
oc apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: openshift-default
spec:
  controllerName: openshift.io/gateway-controller/v1
EOF

oc get gatewayclass openshift-default
```


Apply the route (needed to be manually created on ROSA):
```bash
envsubst < route.yaml | oc apply -f -
# check
oc get route -n openshift-ingress -l gateway.networking.k8s.io/gateway-name=$TENANT_NAME
```


Obtain the infra NS, place where the tenant api is deployed along with the test postgresql database.
```bash
INFRA_NS=$(oc get deployment -A -o custom-columns=NS:.metadata.namespace,NAME:.metadata.name --no-headers | grep "maas-api-${TENANT_NAME}" | awk '{print $1}')
```