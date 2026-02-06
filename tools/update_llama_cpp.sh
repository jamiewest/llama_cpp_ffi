#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE_DIR="${ROOT_DIR}/src/llama.cpp"
UPSTREAM_REPO="ggml-org/llama.cpp"

git -C "${ROOT_DIR}" submodule sync -- "src/llama.cpp"

if [[ ! -d "${SUBMODULE_DIR}" ]]; then
  echo "submodule missing at ${SUBMODULE_DIR}; initializing..."
  git -C "${ROOT_DIR}" submodule update --init --recursive "src/llama.cpp"
fi

if [[ ! -d "${SUBMODULE_DIR}" ]]; then
  echo "error: expected submodule at ${SUBMODULE_DIR} after init" >&2
  exit 1
fi

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

fetch_release_json() {
  local url="https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest"
  local response status body

  response="$(curl -sS -w $'\n%{http_code}' "${auth_header[@]}" "${url}")"
  status="${response##*$'\n'}"
  body="${response%$'\n'*}"

  if [[ "${status}" == "401" && ${#auth_header[@]} -gt 0 ]]; then
    echo "warning: GITHUB_TOKEN rejected; retrying without auth" >&2
    response="$(curl -sS -w $'\n%{http_code}' "${url}")"
    status="${response##*$'\n'}"
    body="${response%$'\n'*}"
  fi

  if [[ "${status}" != "200" ]]; then
    echo "error: GitHub API returned HTTP ${status}" >&2
    if [[ -n "${body}" ]]; then
      echo "${body}" >&2
    fi
    return 1
  fi

  printf '%s' "${body}"
}

release_json="$(fetch_release_json)"

latest_tag="$(
  RELEASE_JSON="${release_json}" python3 - <<'PY'
import json, os, sys
raw = os.environ.get("RELEASE_JSON", "")
try:
  data = json.loads(raw)
except json.JSONDecodeError as exc:
  print("", end="")
  sys.exit(0)

if isinstance(data, dict):
  print(data.get("tag_name", ""))
else:
  print("", end="")
PY
)"

if [[ -z "${latest_tag}" ]]; then
  echo "error: could not determine latest release tag from GitHub API" >&2
  exit 1
fi

git -C "${SUBMODULE_DIR}" fetch --tags origin
git -C "${SUBMODULE_DIR}" checkout "${latest_tag}"

(
  cd "${ROOT_DIR}"
  dart run ffigen
)

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "llama_cpp_tag=${latest_tag}" >> "${GITHUB_OUTPUT}"
fi

echo "Updated llama.cpp to ${latest_tag}"
