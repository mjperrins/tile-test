#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)

CHART_NAME="$1"
NAMESPACE="$2"
VERSION="$3"
INGRESS_HOST="$4"
INGRESS_SUBDOMAIN="$5"
ENABLE_ARGO_CACHE="$6"
ROUTE_TYPE="$7"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi

if [[ -z "${ROUTE_TYPE}" ]]; then
  ROUTE_TYPE="passthrough"
fi

if [[ -z "${TLS_SECRET_NAME}" ]]; then
  TLS_SECRET_NAME="argocd-secret"
fi

NAME="argocd"

KUSTOMIZE_TEMPLATE="${MODULE_DIR}/kustomize/argocd"
KUSTOMIZE_PATCH_TEMPLATE="${KUSTOMIZE_TEMPLATE}/patch-ingress.yaml"

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"
KUSTOMIZE_PATCH="${KUSTOMIZE_DIR}/argocd/patch-ingress.yaml"

ARGOCD_CHART="${CHART_DIR}/${CHART_NAME}"
SOLSACM_CHART="${MODULE_DIR}/charts/solsa-cm"

ARGOCD_KUSTOMIZE="${KUSTOMIZE_DIR}/argocd"
ARGOCD_BASE_KUSTOMIZE="${ARGOCD_KUSTOMIZE}/base.yaml"
ARGOCD_SOLSACM_KUSTOMIZE="${ARGOCD_KUSTOMIZE}/solsa/solsa-cm.yaml"

ARGOCD_YAML="${TMP_DIR}/argocd.yaml"
SECRET_OUTPUT_YAML="${TMP_DIR}/argocd-secret.yaml"

HELM_REPO="https://argoproj.github.io/argo-helm/"

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

HELM_VALUES="redis.enabled=${ENABLE_ARGO_CACHE}"
if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HELM_VALUES="${HELM_VALUES},server.ingress.enabled=false,server.ingress.hosts.0=${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"

  if [[ -n "${TLS_SECRET_NAME}" ]]; then
    HELM_VALUES="${HELM_VALUES},server.ingress.tls[0].secretName=${TLS_SECRET_NAME},server.ingress.tls[0].hosts[0]=${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
  fi

  URL="https://${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
fi

echo "*** Generating kube yaml from helm template into ${ARGOCD_BASE_KUSTOMIZE}"
helm3 template "${NAME}" "${CHART_NAME}" \
    --repo "${HELM_REPO}" \
    --include-crds \
    --version "${VERSION}" \
    --namespace "${NAMESPACE}" \
    --set installCRDs=false \
    --set "${HELM_VALUES}" > ${ARGOCD_BASE_KUSTOMIZE}

echo "*** Generating solsa-cm yaml from helm template into ${ARGOCD_SOLSACM_KUSTOMIZE}"
helm3 template solsacm "${SOLSACM_CHART}" \
    --namespace "${NAMESPACE}" \
    --set ingress.subdomain="${INGRESS_SUBDOMAIN}" \
    --set ingress.tlssecret="${TLS_SECRET_NAME}" > ${ARGOCD_SOLSACM_KUSTOMIZE}

echo "*** Building final kube yaml from kustomize into ${ARGOCD_YAML}"
kustomize build "${ARGOCD_KUSTOMIZE}" > "${ARGOCD_YAML}"

echo "*** Applying kube yaml ${ARGOCD_YAML}"
kubectl apply -n "${NAMESPACE}" -f "${ARGOCD_YAML}"


if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5

  oc create route "${ROUTE_TYPE}" argocd --service=argocd-server --port=https --insecure-policy=Redirect -n "${NAMESPACE}"

  HOST=$(oc get route argocd -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  URL="https://${HOST}"

  DEX_TOKEN=$(oc serviceaccounts get-token argocd-dex-server -n "${NAMESPACE}")
  OAUTH_URL="https://${HOST}/api/dex/callback"
  SERVER_URL=$(oc whoami --show-server)

#  oc patch serviceaccount argocd-dex-server -n "${NAMESPACE}" --type='json' -p="[{\"op\": \"add\", \"path\": \"/metadata/annotations/serviceaccounts.openshift.io~1oauth-redirecturi.argocd\", \"value\":\"${OAUTH_URL\"}]"

  cat > "${MODULE_DIR}/argocd-url-patch.yaml" << EOL
data:
  url: ${URL}
EOL

  kubectl patch configmap argocd-cm --type merge --patch "$(cat ${MODULE_DIR}/argocd-url-patch.yaml)" -n "${NAMESPACE}"

  cat > "${TMP_DIR}/argocd-dex-patch.yaml" << EOL
data:
  dex.config: |
    connectors:
    - type: openshift
      id: openshift
      name: OpenShift
      config:
        issuer: ${SERVER_URL}
        clientID: system:serviceaccount:${NAMESPACE}:argocd-dex-server
        clientSecret: ${DEV_TOKEN}
        redirectURI: ${OAUTH_URL}
        insecureCA: true
EOL

  # don't apply this patch right now
  #kubectl patch configmap argocd-cm --type merge --patch "$(cat ${TMP_DIR}/argocd-dex-patch.yaml)"
else
  # create ingress
  echo "creating ingress for IKS"
    cat > "${TMP_DIR}/argocd-ingress.yaml" << EOL
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: argocd-server-http-ingress
  labels:
    app: ${NAME}
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: argocd-server
          servicePort: http
        path: "/"
    host: "${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
  tls:
  - hosts:
    - "${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
    secretName: ${TLS_SECRET_NAME}
---
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: argocd-server-grpc-ingress
  labels:
    app: ${NAME}
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/backend-protocol: "GRPC"
spec:
  rules:
  - http:
      paths:
      - backend:
          serviceName: argocd-server
          servicePort: https
        path: "/"
    host: "grpc.${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
  tls:
  - hosts:
    - "grpc.${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
    secretName: ${TLS_SECRET_NAME}
EOL

  kubectl apply -n "${NAMESPACE}" -f "${TMP_DIR}/argocd-ingress.yaml"
fi

sleep 5
PASSWORD=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')

helm3 repo add toolkit-charts https://ibm-garage-cloud.github.io/toolkit-charts/
helm3 template argocd-config toolkit-charts/tool-config \
  --namespace "${NAMESPACE}" \
  --set name=argocd \
  --set username=admin \
  --set password="${PASSWORD}" \
  --set url="${URL}" > "${SECRET_OUTPUT_YAML}"

kubectl apply -n "${NAMESPACE}" -f "${SECRET_OUTPUT_YAML}"

echo "*** Waiting for ArgoCD"
"${SCRIPT_DIR}/waitForEndpoint.sh" "${URL}" 150 12
