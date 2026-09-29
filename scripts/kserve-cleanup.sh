#!/bin/bash

# KServe, LLM-d, and ODH-Model-Controller Complete Cleanup Script
# This script will force delete all related resources including:
# - InferenceServices across all namespaces
# - KServe-related CRDs
# - llm-d related resources
# - odh-model-controller related resources
# - KServe webhooks (mutating and validating)
# - KServe-related namespaces

set -e

echo "Starting comprehensive KServe cleanup..."
echo "WARNING: This will force delete resources without waiting for graceful termination!"
echo ""

# Function to safely delete resources with error handling
safe_delete() {
    local resource_type="$1"
    local resource_name="$2"
    local additional_args="$3"

    if kubectl get "$resource_type" "$resource_name" &>/dev/null; then
        echo "Deleting $resource_type: $resource_name"
        kubectl delete "$resource_type" "$resource_name" $additional_args || echo "Warning: Failed to delete $resource_type $resource_name"
    else
        echo "No $resource_type named '$resource_name' found"
    fi
}

# Function to delete all resources of a type matching a pattern
delete_matching_resources() {
    local resource_type="$1"
    local pattern="$2"
    local additional_args="$3"

    echo "Searching for $resource_type matching pattern: $pattern"
    local resources=$(kubectl get "$resource_type" 2>/dev/null | grep -E "$pattern" | awk '{print $1}' || true)

    if [ -n "$resources" ]; then
        for resource in $resources; do
            safe_delete "$resource_type" "$resource" "$additional_args"
        done
    else
        echo "No $resource_type found matching pattern: $pattern"
    fi
}

echo "=== Step 1: Deleting all InferenceServices across all namespaces ==="
if kubectl get inferenceservices --all-namespaces &>/dev/null; then
    echo "Force deleting all InferenceServices..."
    kubectl delete inferenceservices --all --all-namespaces --force --grace-period=0 || echo "Warning: Some InferenceServices may not have been deleted"
else
    echo "No InferenceServices found in cluster"
fi
echo ""

echo "=== Step 2: Deleting KServe-related namespaces ==="
# List of potential KServe namespaces to delete
KSERVE_NAMESPACES=(
    "kserve"
    "kserve-raw"
    "kserve-ci-e2e-test"
    "serving-system"
    "knative-serving"
)

for ns in "${KSERVE_NAMESPACES[@]}"; do
    if kubectl get namespace "$ns" &>/dev/null; then
        echo "Force deleting namespace: $ns"
        kubectl delete namespace "$ns" --force --grace-period=0 || echo "Warning: Failed to delete namespace $ns"

        # If namespace gets stuck, try to remove finalizers
        if kubectl get namespace "$ns" &>/dev/null; then
            echo "Namespace $ns stuck, trying to remove finalizers..."
            kubectl get namespace "$ns" -o json | jq '.spec.finalizers = []' | kubectl replace --raw /api/v1/namespaces/$ns/finalize -f - || echo "Warning: Failed to remove finalizers from namespace $ns"
        fi
    else
        echo "Namespace '$ns' not found"
    fi
done
echo ""

echo "=== Step 3: Deleting KServe-related CRDs ==="
# List of potential KServe CRDs to delete
KSERVE_CRDS=(
    "inferenceservices.serving.kserve.io"
    "predictors.serving.kserve.io"
    "trainedmodels.serving.kserve.io"
    "clusterservingruntimes.serving.kserve.io"
    "servingruntimes.serving.kserve.io"
)

for crd in "${KSERVE_CRDS[@]}"; do
    safe_delete "crd" "$crd" "--force --grace-period=0"
done

# Delete any remaining serving.kserve.io CRDs
delete_matching_resources "crd" "serving\.kserve\.io" "--force --grace-period=0"
echo ""

echo "=== Step 4: Deleting LLM-d related resources ==="
# Delete LLM-related CRDs
delete_matching_resources "crd" "llm" "--force --grace-period=0"

# Delete LLM-related namespaces
LLM_NAMESPACES=(
    "llm-d"
    "llm-serving"
)

for ns in "${LLM_NAMESPACES[@]}"; do
    safe_delete "namespace" "$ns" "--force --grace-period=0"
done
echo ""

echo "=== Step 5: Deleting ODH-Model-Controller related resources ==="
# Delete ODH-related CRDs
ODH_CRDS=(
    "odhquickstarts.console.openshift.io"
    "odhapplications.dashboard.opendatahub.io"
    "odhdocuments.dashboard.opendatahub.io"
)

for crd in "${ODH_CRDS[@]}"; do
    safe_delete "crd" "$crd" "--force --grace-period=0"
done

# Delete any remaining ODH CRDs
delete_matching_resources "crd" "opendatahub\.io|odh" "--force --grace-period=0"

# Delete ODH-related namespaces
ODH_NAMESPACES=(
    "opendatahub"
    "odh-model-controller"
    "rhods-operator"
)

for ns in "${ODH_NAMESPACES[@]}"; do
    safe_delete "namespace" "$ns" "--force --grace-period=0"
done
echo ""

echo "=== Step 6: Deleting KServe webhooks ==="
# Delete validating admission webhooks
VALIDATING_WEBHOOKS=(
    "kserve-webhook-server-validator"
    "inferenceservice-webhook-server"
    "serving-kserve-webhook"
)

for webhook in "${VALIDATING_WEBHOOKS[@]}"; do
    safe_delete "validatingwebhookconfigurations" "$webhook" "--force --grace-period=0"
done

# Delete any remaining KServe validating webhooks
delete_matching_resources "validatingwebhookconfigurations" "kserve|serving|inference" "--force --grace-period=0"

# Delete mutating admission webhooks
MUTATING_WEBHOOKS=(
    "kserve-webhook-server-mutator"
    "inferenceservice-mutating-webhook"
    "serving-kserve-mutating-webhook"
)

for webhook in "${MUTATING_WEBHOOKS[@]}"; do
    safe_delete "mutatingwebhookconfigurations" "$webhook" "--force --grace-period=0"
done

# Delete any remaining KServe mutating webhooks
delete_matching_resources "mutatingwebhookconfigurations" "kserve|serving|inference" "--force --grace-period=0"
echo ""

echo "=== Step 7: Additional cleanup for stuck resources ==="
# Force delete any remaining inference-related resources that might be stuck
echo "Checking for any remaining inference-related resources..."

# Check for any remaining InferenceServices that might have been recreated
if kubectl get inferenceservices --all-namespaces &>/dev/null; then
    echo "Found remaining InferenceServices, force deleting again..."
    kubectl delete inferenceservices --all --all-namespaces --force --grace-period=0 || true
fi

# Check for any test or CI namespaces that might have been recreated
TEST_NAMESPACES=($(kubectl get namespaces | grep -E "(test|ci.*e2e)" | awk '{print $1}' || true))
if [ ${#TEST_NAMESPACES[@]} -gt 0 ]; then
    echo "Found test/CI namespaces, deleting: ${TEST_NAMESPACES[*]}"
    for ns in "${TEST_NAMESPACES[@]}"; do
        kubectl delete namespace "$ns" --force --grace-period=0 || true
    done
fi

echo ""
echo "=== Cleanup Summary ==="
echo "Checking remaining resources..."

echo "Remaining InferenceServices:"
kubectl get inferenceservices --all-namespaces 2>/dev/null || echo "No InferenceServices found"

echo ""
echo "Remaining KServe/Serving CRDs:"
kubectl get crd | grep -E "(serving\.kserve|kserve|inference)" || echo "No KServe/Serving CRDs found"

echo ""
echo "Remaining KServe/Serving namespaces:"
kubectl get namespaces | grep -E "(kserve|serving|llm|odh)" || echo "No KServe/Serving namespaces found"

echo ""
echo "Remaining KServe webhooks:"
echo "Validating webhooks:"
kubectl get validatingwebhookconfigurations | grep -E "(kserve|serving|inference)" || echo "No KServe validating webhooks found"
echo "Mutating webhooks:"
kubectl get mutatingwebhookconfigurations | grep -E "(kserve|serving|inference)" || echo "No KServe mutating webhooks found"

echo ""
echo "✅ KServe cleanup completed!"
echo "Note: Some resources may still be terminating in the background."
echo "If you encounter any stuck resources, you may need to manually patch finalizers."