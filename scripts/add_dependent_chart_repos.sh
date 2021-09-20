#!/usr/bin/env bash
set -euo pipefail

# CHART_NAME=${CHART_NAME:?"required value not set"}
CHART_REPO=${CHART_REPO:?"required value not set"}

function find_dependencies() {
  local path=$1

  find "$path" -mindepth 1 -maxdepth 1 -name "*.yaml" -type f -print0 | \
  xargs -0 grep -El "^dependencies:"
}

function add_dependent_chart_repos() {
  local chart_repo chart_name path
  chart_repo="$1"
  chart_name="$2"
  path="${chart_repo}/${chart_name}/"

  deps=$(find_dependencies "$path") || { echo "No dependent charts found for ${chart_name}"; exit 0; }

  while read -r -a repo;
    do helm repo add "${repo[0]}" "${repo[1]}";
  done <<< "$(yq -r '.dependencies[] | [.name,.repository] | @tsv' "${deps}")"

  helm repo update
}

function update_chart_dependencies() {
  local chart_repo chart_name path
  chart_repo="$1"
  chart_name="$2"
  path="${chart_repo}/${chart_name}/"

  helm dependency update "$path"
}

for CHART_NAME in $(find "$CHART_REPO" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' ); do
  echo "Finding dependent charts for $CHART_NAME"
  add_dependent_chart_repos "${CHART_REPO}" "${CHART_NAME}";
  update_chart_dependencies "${CHART_REPO}" "${CHART_NAME}";
done
