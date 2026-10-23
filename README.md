# Amalgamator website

Hugo site for [Amalgamator](https://github.com/amalgamator-ai/amalgamator), published at [amalgamator-ai.github.io](https://amalgamator-ai-github.io/).

Product documentation is sourced from the `amalgamator` git submodule (`sources/amalgamator/docs`). Landing, blog, and community pages are authored in this repository.

## Requirements

- [Hugo Extended](https://gohugo.io/installation/) 0.146+ (0.168 recommended)
- Python 3 (for `make prepare-docs`)
- Git (submodules)

## Build and preview

```sh
make init
make serve
```

Open http://localhost:1313/. Production build:

```sh
make build
```

Output lands in `public/`. GitHub Pages deploys from `.github/workflows/pages.yml` on push to `main`.

## Pull request previews (Netlify)

Production stays on **GitHub Pages**. PR previews deploy via [`.github/workflows/netlify-preview.yml`](.github/workflows/netlify-preview.yml) (not Netlify’s Git auto-build — see [`netlify.toml`](netlify.toml)).

**This repo’s PRs:** open a PR; the workflow builds with `HUGO_BASEURL` for alias `deploy-preview-<n>`, deploys to Netlify, and comments the URL on the PR.

**Required on this repo** (Settings → Secrets and variables → Actions):

- Secrets: `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`
- Secret: `AMALGAMATOR_REPO_TOKEN` — required while [amalgamator](https://github.com/amalgamator-ai/amalgamator) is **private**. This website’s `GITHUB_TOKEN` cannot read sibling private repos (submodule + docs checkout). Use a fine-grained PAT (or classic PAT) with **Contents: Read** on `amalgamator-ai/amalgamator`, stored as that secret.
- Optional variable: `NETLIFY_SITE_NAME` (looked up via the API when unset)
- Optional secret: `CROSS_REPO_COMMENT_TOKEN` — only needed for `repository_dispatch` previews that must comment on amalgamator PRs

When amalgamator calls this workflow via `workflow_call`, pass `AMALGAMATOR_REPO_TOKEN: ${{ github.token }}` so the job can read the private product repo with the caller’s token.

In the Netlify UI, turn off automatic Deploy Previews / stop builds for the linked GitHub repo so App checks do not fail on skipped builds.

**Docs PRs on amalgamator:** this workflow is also a reusable `workflow_call` and listens for `repository_dispatch` type `docs-preview`. Copy the starter from [`examples/amalgamator-docs-netlify-preview.yml`](examples/amalgamator-docs-netlify-preview.yml) into the product repo when ready. Cross-repo runs check out amalgamator `docs/` at the PR SHA (`DOCS_SOURCE`), deploy as `docs-preview-<n>`, and comment on the caller PR.

## Updating docs

Docs stay authoritative in [amalgamator-ai/amalgamator](https://github.com/amalgamator-ai/amalgamator). `make prepare-docs` mounts `sources/amalgamator/docs` when that tree exists. Until user guides land on `main`, builds fall back to the snapshot in [`vendor/docs`](vendor/docs).

Bump the submodule when product docs are available:

```sh
cd sources/amalgamator && git fetch && git checkout <ref> && cd ../..
git add sources/amalgamator
make build
```

Refresh the vendor snapshot from a local product checkout if needed:

```sh
rsync -a --delete --include='*/' --include='*.md' --exclude='*' \
  /path/to/amalgamator/docs/ vendor/docs/
```

Navigation titles and weights live in [`data/docs_nav.yaml`](data/docs_nav.yaml).
