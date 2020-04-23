#!/usr/bin/env bash

NAMESPACE="$1"
PRE_TEKTON="$2"
REVISION="$3"
GIT_URL="$4"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=./.tmp
fi
mkdir -p "${TMP_DIR}"

TASK_DIR="${TMP_DIR}/ibm-garage-tekton-tasks"

git clone --branch "${REVISION}" "${GIT_URL}" "${TASK_DIR}"

echo "*** Waiting for Tekton API group to be available"
until oc get tasks
do
    echo '>>> waiting for Tekton APIs availability'
    sleep 60
done
echo '>>> Tekton APIs are available'

if [[ "${PRE_TEKTON}" == "true" ]]; then
  kubectl create -f "${TASK_DIR}/pre-0.7.0/tasks/" -n "${NAMESPACE}"
else
  kubectl create -f "${TASK_DIR}/tasks/" -n "${NAMESPACE}"
fi
kubectl create -f "${TASK_DIR}/pipelines/" -n "${NAMESPACE}"
