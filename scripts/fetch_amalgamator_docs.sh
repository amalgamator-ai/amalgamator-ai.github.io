#!/usr/bin/env bash
# Clone amalgamator docs/ into DEST using AMALGAMATOR_REPO_TOKEN (HTTPS) or
# AMALGAMATOR_DEPLOY_KEY (SSH).
#
# Verifies Contents access — GET /repos/:owner/:repo alone only needs Metadata
# and will false-positive while git clone still 403s.
set -euo pipefail

REF="${1:?usage: fetch_amalgamator_docs.sh <ref> [dest]}"
DEST="${2:-.cache/amalgamator-src}"
API="https://api.github.com/repos/amalgamator-ai/amalgamator"

rm -rf "${DEST}"
mkdir -p "${DEST}"

require_docs() {
  if [ ! -f "${DEST}/docs/getting-started.md" ]; then
    echo "::error::After clone, ${DEST}/docs/getting-started.md is missing (ref=${REF})."
    ls -la "${DEST}" || true
    ls -la "${DEST}/docs" || true
    exit 1
  fi
  echo "Docs ready at ${DEST}/docs (ref=${REF})"
}

fetch_into() {
  local remote_url="$1"
  git -C "${DEST}" init -q
  git -C "${DEST}" remote add origin "${remote_url}"
  git -C "${DEST}" sparse-checkout init --cone
  git -C "${DEST}" sparse-checkout set docs
  # Works for branch names and commit SHAs.
  git -C "${DEST}" fetch --depth 1 --filter=blob:none origin "${REF}"
  git -C "${DEST}" checkout --force FETCH_HEAD
}

if [ -n "${AMALGAMATOR_DEPLOY_KEY:-}" ]; then
  echo "Fetching amalgamator@${REF} via deploy key (SSH)"
  key_file="$(mktemp)"
  printf '%s\n' "${AMALGAMATOR_DEPLOY_KEY}" > "${key_file}"
  chmod 600 "${key_file}"
  export GIT_SSH_COMMAND="ssh -i ${key_file} -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new"
  fetch_into "git@github.com:amalgamator-ai/amalgamator.git"
  rm -f "${key_file}"
elif [ -n "${AMALGAMATOR_REPO_TOKEN:-}" ]; then
  echo "Fetching amalgamator@${REF} via AMALGAMATOR_REPO_TOKEN (HTTPS)"
  # Contents check (not Metadata-only).
  code="$(curl -sS -o /tmp/amalgamator-contents.json -w '%{http_code}' \
    -H "Authorization: Bearer ${AMALGAMATOR_REPO_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "${API}/contents/docs?ref=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=''))" "${REF}")")"
  if [ "${code}" != "200" ]; then
    echo "::error::AMALGAMATOR_REPO_TOKEN cannot read docs/ on amalgamator@${REF} (HTTP ${code})."
    echo "::error::Body: $(head -c 500 /tmp/amalgamator-contents.json)"
    echo "::error::Your PAT can see the repo metadata but not Contents — git clone will 403."
    echo "::error::Recreate a fine-grained PAT: resource owner amalgamator-ai, repository amalgamator, permission Contents: Read."
    echo "::error::Or add a read-only deploy key on amalgamator and set secret AMALGAMATOR_DEPLOY_KEY on this repo."
    exit 1
  fi
  fetch_into "https://x-access-token:${AMALGAMATOR_REPO_TOKEN}@github.com/amalgamator-ai/amalgamator.git"
else
  echo "::error::Set secret AMALGAMATOR_REPO_TOKEN (Contents:Read on amalgamator) or AMALGAMATOR_DEPLOY_KEY (read-only deploy key)."
  exit 1
fi

require_docs
