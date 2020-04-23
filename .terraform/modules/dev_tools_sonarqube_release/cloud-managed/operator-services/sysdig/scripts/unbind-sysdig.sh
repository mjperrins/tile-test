#!/usr/bin/env bash

NAMESPACE="ibm-observe"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
   export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -n $(kubectl get namespaces -o jsonpath='{ range .items[*] }{ .metadata.name }{ "\n" }{ end }' | grep "${NAMESPACE}") ]]; then
    echo "*** Deleting namespace and contained resources: ${NAMESPACE}"
    kubectl delete daemonsets,replicasets,services,deployments,pods,rc,ing,statefulsets,crds,secrets --all -n "${NAMESPACE}"
    kubectl delete namespace "${NAMESPACE}"
fi
