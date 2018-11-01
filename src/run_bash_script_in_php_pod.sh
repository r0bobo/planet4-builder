#!/usr/bin/env bash
set -exu

external_script="$1"

php=$(kubectl get pods --namespace "${HELM_NAMESPACE}" --field-selector=status.phase=Running -l "app=wordpress-php,release=${HELM_RELEASE}" -o jsonpath="{.items[0].metadata.name}")

if [[ -z "$php" ]]
then
  >&2 echo "ERROR: php pod not found in release ${HELM_RELEASE}"
fi

if [[ ! -e "$1" ]]
then
  >&2 echo "ERROR: file does not exist: '$1'"
fi

kubectl -n "${HELM_NAMESPACE}" cp "$external_script" "$php:/app/bin/$external_script"
kubectl -n "${HELM_NAMESPACE}" exec "$php" bash "/app/bin/$external_script"
kubectl -n "${HELM_NAMESPACE}" exec "$php" rm "/app/bin/$external_script"
