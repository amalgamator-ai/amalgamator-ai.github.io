# Amalgamator website

Hugo site for [Amalgamator](https://github.com/amalgamator-ai/amalgamator), published at [amalgamator-ai.github.io](https://amalgamator-ai.github.io/).

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
