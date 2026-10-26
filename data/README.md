# Hugo data (website-only)

Product documentation sidebar titles and weights live in the amalgamator
repository at [`docs/docs_nav.yaml`](https://github.com/amalgamator-ai/amalgamator/blob/main/docs/docs_nav.yaml).

`make prepare-docs` copies that file to `.cache/data/docs_nav.yaml`, which Hugo
mounts as `data/docs_nav`. Keep this directory for **website-only** data files
(landing/blog/community), not product doc navigation.
