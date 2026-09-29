#!/bin/bash
set -euo pipefail

# Cleanup Script for cert-manager and Kuadrant Operators
# This script removes cert-manager and Kuadrant operators and all their resources

CERT_MANAGER_VERSION=${CERT_MANAGER_VERSION:-v1.18.2}
KUADRANT_NAMESPACE=${KUADRANT_NAMESPACE:-kuadrant-system}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}❌${NC} $1"
}

cleanup_cert_manager() {
    echo ""
    log_info "=== Cleaning up cert-manager ==="
    echo ""
    
    # Delete cert-manager using the installation manifest
    log_info "Deleting cert-manager resources..."
    if kubectl delete -f https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.yaml 2>&1 | grep -v "NotFound"; then
        log_success "cert-manager resources deleted"
    else
        log_warning "Some cert-manager resources were already deleted or not found"
    fi
    
    # Verify namespace deletion
    echo ""
    log_info "Verifying cert-manager namespace deletion..."
    if kubectl get namespace cert-manager &>/dev/null; then
        log_warning "cert-manager namespace still exists"
    else
        log_success "cert-manager namespace confirmed deleted"
    fi
    
    # Verify CRDs deletion
    log_info "Verifying cert-manager CRDs deletion..."
    if kubectl get crds 2>/dev/null | grep -q cert-manager; then
        log_warning "Some cert-manager CRDs still exist"
    else
        log_success "All cert-manager CRDs confirmed deleted"
    fi
    
    # Verify webhook configurations deletion
    log_info "Verifying cert-manager webhook configurations deletion..."
    if kubectl get mutatingwebhookconfigurations,validatingwebhookconfigurations 2>/dev/null | grep -q cert-manager; then
        log_warning "Some cert-manager webhook configurations still exist"
    else
        log_success "All cert-manager webhook configurations confirmed deleted"
    fi
}

cleanup_kuadrant() {
    echo ""
    log_info "=== Cleaning up Kuadrant operator ==="
    echo ""
    
    # Delete Kuadrant custom resource
    log_info "Deleting Kuadrant custom resource..."
    if kubectl get kuadrant kuadrant -n "$KUADRANT_NAMESPACE" &>/dev/null; then
        kubectl delete kuadrant kuadrant -n "$KUADRANT_NAMESPACE" --timeout=30s || {
            log_warning "Kuadrant resource deletion timed out, removing finalizers..."
            kubectl patch kuadrant kuadrant -n "$KUADRANT_NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        }
        log_success "Kuadrant custom resource deleted"
    else
        log_info "No Kuadrant custom resource found"
    fi
    
    # Delete Limitador custom resource
    log_info "Deleting Limitador custom resource..."
    if kubectl get limitador limitador -n "$KUADRANT_NAMESPACE" &>/dev/null; then
        kubectl delete limitador limitador -n "$KUADRANT_NAMESPACE" --timeout=30s || {
            log_warning "Limitador resource deletion timed out, removing finalizers..."
            kubectl patch limitador limitador -n "$KUADRANT_NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        }
        log_success "Limitador custom resource deleted"
    else
        log_info "No Limitador custom resource found"
    fi
    
    # Delete Authorino custom resource (if exists)
    log_info "Deleting Authorino custom resource..."
    if kubectl get authorino -n "$KUADRANT_NAMESPACE" &>/dev/null; then
        kubectl delete authorino authorino -n "$KUADRANT_NAMESPACE" --timeout=30s || {
            log_warning "Authorino resource deletion timed out, removing finalizers..."
            kubectl patch authorino authorino -n "$KUADRANT_NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge || true
        }
        log_success "Authorino custom resource deleted"
    else
        log_info "No Authorino custom resource found"
    fi
    
    # Delete namespace
    log_info "Deleting $KUADRANT_NAMESPACE namespace..."
    if kubectl get namespace "$KUADRANT_NAMESPACE" &>/dev/null; then
        kubectl delete namespace "$KUADRANT_NAMESPACE" --timeout=60s &
        NAMESPACE_PID=$!
        
        # Wait for namespace deletion with timeout
        sleep 10
        if kubectl get namespace "$KUADRANT_NAMESPACE" &>/dev/null; then
            log_warning "Namespace deletion in progress, checking for stuck resources..."
            
            # Check for stuck resources and remove finalizers if needed
            if kubectl get kuadrants.kuadrant.io -n "$KUADRANT_NAMESPACE" -o json 2>/dev/null | grep -q "kuadrant.io/finalizer"; then
                log_info "Removing finalizers from stuck Kuadrant resources..."
                kubectl patch kuadrant kuadrant -n "$KUADRANT_NAMESPACE" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
            fi
            
            # Remove namespace finalizers if it's still stuck
            if kubectl get namespace "$KUADRANT_NAMESPACE" &>/dev/null; then
                log_info "Removing namespace finalizers..."
                kubectl get namespace "$KUADRANT_NAMESPACE" -o json | jq '.spec.finalizers = []' | kubectl replace --raw /api/v1/namespaces/"$KUADRANT_NAMESPACE"/finalize -f - 2>/dev/null || true
            fi
        fi
        
        # Wait for the background process
        wait $NAMESPACE_PID 2>/dev/null || true
        
        # Final check
        if kubectl get namespace "$KUADRANT_NAMESPACE" &>/dev/null; then
            log_error "Namespace $KUADRANT_NAMESPACE still exists after cleanup attempts"
        else
            log_success "$KUADRANT_NAMESPACE namespace deleted"
        fi
    else
        log_info "Namespace $KUADRANT_NAMESPACE already deleted"
    fi
    
    # Delete CRDs
    echo ""
    log_info "Deleting Kuadrant-related CRDs..."
    
    KUADRANT_CRDS=(
        "authpolicies.kuadrant.io"
        "dnspolicies.kuadrant.io"
        "dnsrecords.kuadrant.io"
        "kuadrants.kuadrant.io"
        "limitadors.limitador.kuadrant.io"
        "ratelimitpolicies.kuadrant.io"
        "tlspolicies.kuadrant.io"
        "authconfigs.authorino.kuadrant.io"
        "authorinos.operator.authorino.kuadrant.io"
    )
    
    for crd in "${KUADRANT_CRDS[@]}"; do
        if kubectl get crd "$crd" &>/dev/null; then
            log_info "Deleting CRD: $crd"
            kubectl delete crd "$crd" --timeout=30s || {
                log_warning "CRD deletion timed out, removing finalizers..."
                kubectl patch crd "$crd" -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
                kubectl delete crd "$crd" --force --grace-period=0 2>/dev/null || true
            }
        fi
    done
    
    # Verify CRDs deletion
    sleep 2
    log_info "Verifying Kuadrant CRDs deletion..."
    if kubectl get crds 2>/dev/null | grep -E '(kuadrant|limitador|authorino)'; then
        log_warning "Some Kuadrant-related CRDs still exist"
    else
        log_success "All Kuadrant-related CRDs confirmed deleted"
    fi
    
    # Remove Helm repository
    echo ""
    log_info "Removing Kuadrant Helm repository..."
    if helm repo list 2>/dev/null | grep -q kuadrant; then
        helm repo remove kuadrant
        log_success "Kuadrant Helm repository removed"
    else
        log_info "Kuadrant Helm repository not found"
    fi
}

verify_cleanup() {
    echo ""
    log_info "=== Final Cleanup Verification ==="
    echo ""
    
    # Check cert-manager
    log_info "Checking cert-manager..."
    CERT_MANAGER_FOUND=false
    
    if kubectl get namespace cert-manager &>/dev/null; then
        log_warning "cert-manager namespace still exists"
        CERT_MANAGER_FOUND=true
    fi
    
    if kubectl get crds 2>/dev/null | grep -q cert-manager; then
        log_warning "cert-manager CRDs still exist"
        CERT_MANAGER_FOUND=true
    fi
    
    if kubectl get pods -A 2>/dev/null | grep -q cert-manager; then
        log_warning "cert-manager pods still running"
        CERT_MANAGER_FOUND=true
    fi
    
    if [ "$CERT_MANAGER_FOUND" = false ]; then
        log_success "cert-manager completely removed"
    fi
    
    # Check Kuadrant
    echo ""
    log_info "Checking Kuadrant..."
    KUADRANT_FOUND=false
    
    if kubectl get namespace "$KUADRANT_NAMESPACE" &>/dev/null; then
        log_warning "$KUADRANT_NAMESPACE namespace still exists"
        KUADRANT_FOUND=true
    fi
    
    if kubectl get crds 2>/dev/null | grep -qE '(kuadrant|limitador|authorino)'; then
        log_warning "Kuadrant-related CRDs still exist"
        KUADRANT_FOUND=true
    fi
    
    if kubectl get pods -A 2>/dev/null | grep -qE '(kuadrant|limitador|authorino)'; then
        log_warning "Kuadrant-related pods still running"
        KUADRANT_FOUND=true
    fi
    
    if helm list -A 2>/dev/null | grep -qi kuadrant; then
        log_warning "Kuadrant Helm releases still exist"
        KUADRANT_FOUND=true
    fi
    
    if [ "$KUADRANT_FOUND" = false ]; then
        log_success "Kuadrant completely removed"
    fi
    
    echo ""
    if [ "$CERT_MANAGER_FOUND" = false ] && [ "$KUADRANT_FOUND" = false ]; then
        log_success "🎉 All operators successfully cleaned up!"
    else
        log_warning "Some resources may still exist. Please review the warnings above."
    fi
}

main() {
    echo "=========================================="
    echo "  Operator Cleanup Script"
    echo "=========================================="
    echo ""
    echo "This script will remove:"
    echo "  - cert-manager ($CERT_MANAGER_VERSION)"
    echo "  - Kuadrant operator and all components"
    echo ""
    
    read -p "Continue with cleanup? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled."
        exit 0
    fi
    
    # Check prerequisites
    if ! command -v kubectl &>/dev/null; then
        log_error "kubectl not found. Please install kubectl first."
        exit 1
    fi
    
    if ! command -v helm &>/dev/null; then
        log_warning "helm not found. Helm repository cleanup will be skipped."
    fi
    
    if ! command -v jq &>/dev/null; then
        log_warning "jq not found. Some advanced cleanup operations may be skipped."
    fi
    
    # Run cleanup
    cleanup_cert_manager
    cleanup_kuadrant
    verify_cleanup
}

# Run main function
main "$@"

