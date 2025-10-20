#!/usr/bin/env bash
set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)
SRC="$ROOT/kwok/charts"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cp -a "$SRC/." "$TMP/"

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
  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)
  V="${LAST_TAG#v}+${GITHUB_SHA::7}"
  APP="${LAST_TAG#v}"
fi

helm package "$TMP" --version "$V" --app-version "$APP" --destination "$TMP"
ls -1 "$TMP"/${CHART_NAME}-*.tgz


