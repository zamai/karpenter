#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
SRC="$ROOT/kwok/charts"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cp -a "$SRC/." "$TMP/"

# resolve symlinked CRDs by copying from apis/crds into packaged chart
APIS_CRDS_DIR="$ROOT/kwok/apis/crds"
if [[ -d "$APIS_CRDS_DIR" ]]; then
  mkdir -p "$TMP/crds"
  cp -a "$APIS_CRDS_DIR/." "$TMP/crds/"
fi

# override chart name only for packaging
if ! command -v yq >/dev/null 2>&1; then
  echo "yq is required (https://mikefarah.gitbook.io/yq/)" >&2
  exit 1
fi

yq -i '.name = "karPENTER-kwok"' "$TMP/Chart.yaml"
CHART_NAME=$(yq -r '.name' "$TMP/Chart.yaml")

if [[ "${GITHUB_REF_TYPE:-}" == "tag" ]]; then
  V=${GITHUB_REF_NAME#v}
  APP=$V
else
  V="${GITHUB_SHA::7}"
  APP="$V"
fi

helm package "$TMP" --version "$V" --app-version "$APP" --destination "$TMP" >/dev/null
echo "$TMP/${CHART_NAME}-$V.tgz"


