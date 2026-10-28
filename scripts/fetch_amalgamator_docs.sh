#!/usr/bin/env bash
# Shallow-fetch amalgamator docs/ + community policy files into DEST.
# Both repos are public — no tokens or deploy keys required.
set -euo pipefail

REF="${1:?usage: fetch_amalgamator_docs.sh <ref> [dest]}"
DEST="${2:-.cache/amalgamator-src}"
REMOTE="https://github.com/amalgamator-ai/amalgamator.git"

rm -rf "${DEST}"
mkdir -p "${DEST}"

git -C "${DEST}" init -q
git -C "${DEST}" remote add origin "${REMOTE}"
# Non-cone so root policy markdown can be included alongside docs/.
git -C "${DEST}" sparse-checkout init --no-cone
git -C "${DEST}" sparse-checkout set \
  '/docs/**' \
  '/CONTRIBUTING.md' \
  '/CODE_OF_CONDUCT.md' \
  '/SECURITY.md'
# Works for branch names and commit SHAs.
git -C "${DEST}" -c advice.detachedHead=false fetch --depth 1 --filter=blob:none origin "${REF}"
git -C "${DEST}" -c advice.detachedHead=false checkout --force FETCH_HEAD

if [ ! -f "${DEST}/docs/getting-started.md" ]; then
  echo "::error::After clone, ${DEST}/docs/getting-started.md is missing (ref=${REF})."
  ls -la "${DEST}" || true
  ls -la "${DEST}/docs" || true
  exit 1
fi
for f in CONTRIBUTING.md CODE_OF_CONDUCT.md SECURITY.md; do
  if [ ! -f "${DEST}/${f}" ]; then
    echo "::error::After clone, ${DEST}/${f} is missing (ref=${REF})."
    ls -la "${DEST}" || true
    exit 1
  fi
done

echo "Docs ready at ${DEST}/docs (ref=${REF})"
echo "Community policies ready at ${DEST}/{CONTRIBUTING,CODE_OF_CONDUCT,SECURITY}.md"
