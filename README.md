# Amalgamator website

Hugo site for [Amalgamator](https://github.com/amalgamator-ai/amalgamator), published at [amalgamator.ai](https://amalgamator.ai/).

Product documentation and community policies (`CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`) are fetched from the public amalgamator repository. Landing, blog, and community index pages are authored here.

## Requirements

- [Hugo Extended](https://gohugo.io/installation/) 0.146+ (0.168 recommended)
- Python 3 (for `make prepare`)
- Git

## Build and preview

```sh
make serve
```

Open http://localhost:1313/. Production build:

```sh
make build
```

If the optional `sources/amalgamator` submodule has no `docs/` yet, `make prepare` shallow-fetches public amalgamator `main` into `.cache/amalgamator-src`. Override the ref with `AMALGAMATOR_REF=<ref> make fetch-docs`.

Output lands in `public/`. GitHub Pages deploys from [`.github/workflows/pages.yml`](.github/workflows/pages.yml) on push to `main`.

## Pull request previews (Netlify)

Production stays on **GitHub Pages**. PR previews deploy via [`.github/workflows/netlify-preview.yml`](.github/workflows/netlify-preview.yml) (not Netlify’s Git auto-build — see [`netlify.toml`](netlify.toml)).

**This repo’s PRs:** open a PR; the workflow builds with `HUGO_BASEURL` for alias `deploy-preview-<n>`, deploys to Netlify, and comments the URL on the PR.

**Required on this repo** (Settings → Secrets and variables → Actions):

- Secrets: `NETLIFY_AUTH_TOKEN`, `NETLIFY_SITE_ID`
- Optional variable: `NETLIFY_SITE_NAME` (looked up via the API when unset)
- Optional variable: `AMALGAMATOR_DOCS_REF` — amalgamator git ref for “latest” docs (default `main`)

In the Netlify UI, turn off automatic Deploy Previews / stop builds for the linked GitHub repo so App checks do not fail on skipped builds.

**Docs PRs on amalgamator:** copy [`examples/amalgamator-docs-netlify-preview.yml`](examples/amalgamator-docs-netlify-preview.yml) into the product repo. It calls this workflow with the PR SHA as `docs_ref`, deploys as `docs-preview-<n>`, and comments on the caller PR. Netlify secrets must also exist on amalgamator (or be org-level).

## Updating docs

Docs and sidebar nav (`docs/docs_nav.yaml`) stay authoritative in [amalgamator-ai/amalgamator](https://github.com/amalgamator-ai/amalgamator). CI always fetches that tree; locally you can either:

```sh
make fetch-docs                    # .cache/amalgamator-src @ AMALGAMATOR_REF
# or
make init && cd sources/amalgamator && git fetch && git checkout <ref>
```

then `make build`.
