#!/usr/bin/env bash
#
# Override a component image on a live ODH/RHOAI cluster for development.
#
# Follows the flow documented in:
#   https://github.com/opendatahub-io/opendatahub-operator/blob/main/hack/component-dev/README.md
#
# Usage:
#   ./hack/override-component-image.sh <component> <image>
#
# Components:
#   kserve                quay.io/user/kserve-controller:tag
#   odh-model-controller  quay.io/user/odh-model-controller:tag
#
# Examples:
#   ./hack/override-component-image.sh kserve quay.io/spolti/kserve-controller:transformer
#   ./hack/override-component-image.sh odh-model-controller quay.io/spolti/odh-model-controller:latest
#
# Prerequisites:
#   - Logged into an OpenShift cluster with cluster-admin
#   - ODH operator deployed via OLM in openshift-operators
#   - Sibling repos cloned next to opendatahub-tests:
#       ../kserve                (for kserve)
#       ../odh-model-controller  (for odh-model-controller)

set -euo pipefail

OPERATOR_NS="openshift-operators"
OPERATOR_LABEL="name=opendatahub-operator"
STORAGE_CLASS="${STORAGE_CLASS:-gp3-csi}"

# ---------------------------------------------------------------------------
# Component configuration
# ---------------------------------------------------------------------------
declare -A PVC_NAMES=(
    [kserve]="kserve-manifests"
    [odh-model-controller]="modelcontroller-manifests"
)

declare -A MOUNT_PATHS=(
    [kserve]="/opt/manifests/kserve"
    [odh-model-controller]="/opt/manifests/modelcontroller"
)

declare -A PARAMS_FILES=(
    [kserve]="overlays/odh/params.env"
    [odh-model-controller]="base/params.env"
)

declare -A PARAMS_KEYS=(
    [kserve]="kserve-controller"
    [odh-model-controller]="odh-model-controller"
)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { echo "==> $*"; }
error() { echo "ERROR: $*" >&2; exit 1; }

get_operator_pod() {
    oc get po -l "${OPERATOR_LABEL}" -n "${OPERATOR_NS}" \
        -o jsonpath='{.items[0].metadata.name}' 2>/dev/null
}

detect_platform() {
    if oc get namespace redhat-ods-applications &>/dev/null; then
        echo "rhoai"
    elif oc get namespace opendatahub &>/dev/null; then
        echo "odh"
    else
        error "Could not detect platform: neither 'opendatahub' nor 'redhat-ods-applications' namespace found"
    fi
}

wait_for_operator() {
    info "Waiting for operator pod to be ready..."
    oc wait pod -l "${OPERATOR_LABEL}" -n "${OPERATOR_NS}" \
        --for=condition=Ready --timeout=180s
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
COMPONENT="${1:-}"
IMAGE="${2:-}"

if [[ -z "${COMPONENT}" || -z "${IMAGE}" ]]; then
    echo "Usage: $0 <component> <image>"
    echo ""
    echo "Components: kserve, odh-model-controller"
    exit 1
fi

if [[ -z "${PVC_NAMES[${COMPONENT}]+x}" ]]; then
    error "Unknown component '${COMPONENT}'. Supported: kserve, odh-model-controller"
fi

PVC_NAME="${PVC_NAMES[${COMPONENT}]}"
MOUNT_PATH="${MOUNT_PATHS[${COMPONENT}]}"
PARAMS_FILE="${PARAMS_FILES[${COMPONENT}]}"
PARAMS_KEY="${PARAMS_KEYS[${COMPONENT}]}"

# Detect ODH vs RHOAI
PLATFORM="$(detect_platform)"
if [[ "${PLATFORM}" == "rhoai" ]]; then
    DEPLOY_NS="redhat-ods-applications"
    CSV_PATTERN="rhods-operator"
else
    DEPLOY_NS="opendatahub"
    CSV_PATTERN="opendatahub-operator"
fi
info "Platform:   ${PLATFORM}"
info "Deploy NS:  ${DEPLOY_NS}"

# Resolve local manifests directory (sibling repo)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

case "${COMPONENT}" in
    kserve)
        LOCAL_MANIFESTS="${REPO_ROOT}/kserve/config"
        ;;
    odh-model-controller)
        LOCAL_MANIFESTS="${REPO_ROOT}/odh-model-controller/config"
        ;;
esac

if [[ ! -d "${LOCAL_MANIFESTS}" ]]; then
    error "Local manifests not found at ${LOCAL_MANIFESTS}"
fi

info "Component:  ${COMPONENT}"
info "Image:      ${IMAGE}"
info "PVC:        ${PVC_NAME}"
info "Mount:      ${MOUNT_PATH}"
info "Manifests:  ${LOCAL_MANIFESTS}"
echo ""

# Step 1: Create PVC if it doesn't exist
if oc get pvc "${PVC_NAME}" -n "${OPERATOR_NS}" &>/dev/null; then
    info "PVC ${PVC_NAME} already exists"
else
    info "Creating PVC ${PVC_NAME}..."
    oc create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${PVC_NAME}
  namespace: ${OPERATOR_NS}
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ${STORAGE_CLASS}
  resources:
    requests:
      storage: 1Gi
EOF
fi

# Step 2: Patch CSV to mount the PVC (if not already mounted)
CSV=$(oc get csv -n "${OPERATOR_NS}" -o name | grep "${CSV_PATTERN}" | head -n1 | cut -d/ -f2)
info "CSV: ${CSV}"

EXISTING_VOLUMES=$(oc get csv "${CSV}" -n "${OPERATOR_NS}" \
    -o jsonpath='{.spec.install.spec.deployments[0].spec.template.spec.volumes[*].name}')

if echo "${EXISTING_VOLUMES}" | grep -qw "${PVC_NAME}"; then
    info "CSV already has volume ${PVC_NAME}, skipping patch"
else
    info "Patching CSV to mount ${PVC_NAME} at ${MOUNT_PATH}..."
    oc patch csv "${CSV}" -n "${OPERATOR_NS}" --type json -p="$(cat <<EOF
[
  {
    "op": "add",
    "path": "/spec/install/spec/deployments/0/spec/replicas",
    "value": 1
  },
  {
    "op": "add",
    "path": "/spec/install/spec/deployments/0/spec/strategy",
    "value": { "type": "Recreate" }
  },
  {
    "op": "add",
    "path": "/spec/install/spec/deployments/0/spec/template/spec/securityContext/fsGroup",
    "value": 1001
  },
  {
    "op": "add",
    "path": "/spec/install/spec/deployments/0/spec/template/spec/containers/0/volumeMounts/-",
    "value": {
      "name": "${PVC_NAME}",
      "mountPath": "${MOUNT_PATH}"
    }
  },
  {
    "op": "add",
    "path": "/spec/install/spec/deployments/0/spec/template/spec/volumes/-",
    "value": {
      "name": "${PVC_NAME}",
      "persistentVolumeClaim": {
        "claimName": "${PVC_NAME}"
      }
    }
  }
]
EOF
)"
fi

# Step 3: Wait for operator pod
wait_for_operator

# Step 4: Copy manifests into the pod
POD=$(get_operator_pod)
info "Copying manifests into ${POD}:${MOUNT_PATH}..."
oc cp "${LOCAL_MANIFESTS}/." "${OPERATOR_NS}/${POD}:${MOUNT_PATH}"

# Step 5: Override the image in params.env
info "Setting ${PARAMS_KEY}=${IMAGE} in ${PARAMS_FILE}..."
oc exec -n "${OPERATOR_NS}" "${POD}" -- \
    sed -i "s|^${PARAMS_KEY}=.*|${PARAMS_KEY}=${IMAGE}|" "${MOUNT_PATH}/${PARAMS_FILE}"

# Verify
CURRENT=$(oc exec -n "${OPERATOR_NS}" "${POD}" -- \
    grep "^${PARAMS_KEY}=" "${MOUNT_PATH}/${PARAMS_FILE}")
info "Verified: ${CURRENT}"

# Step 6: Restart operator to pick up new manifests
info "Restarting operator..."
oc rollout restart deploy -n "${OPERATOR_NS}" -l "${OPERATOR_LABEL}"
oc rollout status deploy -n "${OPERATOR_NS}" -l "${OPERATOR_LABEL}" --timeout=180s

# Step 7: Force DSC reconciliation
info "Triggering DSC reconciliation..."
oc annotate dsc default-dsc "platform.opendatahub.io/force-reconcile=$(date +%s)" --overwrite

# Step 8: Wait and verify the deployed image
info "Waiting for component rollout..."
sleep 15

case "${COMPONENT}" in
    kserve)
        DEPLOY_NAME="kserve-controller-manager"
        ;;
    odh-model-controller)
        DEPLOY_NAME="odh-model-controller"
        ;;
esac

DEPLOYED_IMAGE=$(oc get deploy "${DEPLOY_NAME}" -n "${DEPLOY_NS}" \
    -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "unknown")

if [[ "${DEPLOYED_IMAGE}" == "${IMAGE}" ]]; then
    info "SUCCESS: ${DEPLOY_NAME} is running ${IMAGE}"
else
    echo ""
    echo "WARNING: Expected ${IMAGE}"
    echo "         Got      ${DEPLOYED_IMAGE}"
    echo ""
    echo "The operator may need more time to reconcile."
    echo "Check with:"
    echo "  oc get deploy ${DEPLOY_NAME} -n ${DEPLOY_NS} -o jsonpath='{.spec.template.spec.containers[0].image}'"
fi