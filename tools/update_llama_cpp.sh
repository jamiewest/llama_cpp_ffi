#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBMODULE_DIR="${ROOT_DIR}/src/llama.cpp"
UPSTREAM_REPO="ggml-org/llama.cpp"

if [[ ! -d "${SUBMODULE_DIR}" ]]; then
  echo "error: expected submodule at ${SUBMODULE_DIR}" >&2
  exit 1
fi

auth_header=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  auth_header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

latest_tag="$(
  curl -sSf "${auth_header[@]}" "https://api.github.com/repos/${UPSTREAM_REPO}/releases/latest" \
    | python3 - <<'PY'
import json, sys
data = json.load(sys.stdin)
print(data.get("tag_name", ""))
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
