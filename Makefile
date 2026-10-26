.PHONY: help init prepare-docs serve build clean

HUGO ?= hugo
HUGO_DESTINATION ?= public
SOURCES_DOCS := sources/amalgamator/docs
VENDOR_DOCS := vendor/docs
CACHE_DOCS := .cache/docs
CACHE_DATA := .cache/data
# Optional override for CI (e.g. amalgamator PR checkout of docs/)
DOCS_SOURCE ?=

help:
	@echo "Targets:"
	@echo "  init           Initialize amalgamator docs submodule"
	@echo "  prepare-docs   Copy product docs + nav; inject Hugo front matter"
	@echo "  serve          Prepare docs and run local Hugo server"
	@echo "  build          Prepare docs and build production site"
	@echo "  clean          Remove generated output and cache"

init:
	@if [ -e sources/amalgamator/.git ] || [ -f sources/amalgamator/README.md ]; then \
		echo "sources/amalgamator already present"; \
	else \
		GIT_LFS_SKIP_SMUDGE=1 git submodule update --init --recursive sources/amalgamator \
			|| echo "Note: submodule init skipped/failed; prepare-docs may use vendor/docs"; \
	fi

# Prefer DOCS_SOURCE, then submodule docs/, then vendor/docs snapshot.
# Product sidebar nav lives in the docs tree (docs_nav.yaml), not in this repo.
prepare-docs: init
	@if [ -n "$(DOCS_SOURCE)" ] && [ -f "$(DOCS_SOURCE)/getting-started.md" ]; then \
		SRC="$(DOCS_SOURCE)"; \
	elif [ -f "$(SOURCES_DOCS)/getting-started.md" ]; then \
		SRC="$(SOURCES_DOCS)"; \
	elif [ -f "$(VENDOR_DOCS)/getting-started.md" ]; then \
		SRC="$(VENDOR_DOCS)"; \
		echo "Note: using $(VENDOR_DOCS) (submodule has no docs/ yet)"; \
	else \
		echo "No docs found in DOCS_SOURCE=$(DOCS_SOURCE), $(SOURCES_DOCS), or $(VENDOR_DOCS)" >&2; exit 1; \
	fi; \
	if [ -f "$$SRC/docs_nav.yaml" ]; then \
		NAV="$$SRC/docs_nav.yaml"; \
	elif [ -f "$$SRC/docs_nav.yml" ]; then \
		NAV="$$SRC/docs_nav.yml"; \
	else \
		echo "Missing docs_nav.yaml (or .yml) in $$SRC — product docs own the sidebar nav." >&2; \
		exit 1; \
	fi; \
	echo "Preparing docs from $$SRC (nav=$$NAV)"; \
	mkdir -p "$(CACHE_DATA)"; \
	cp "$$NAV" "$(CACHE_DATA)/docs_nav.yaml"; \
	python3 scripts/prepare_docs.py --source "$$SRC" --dest "$(CACHE_DOCS)" --nav "$$NAV"

serve: prepare-docs
	$(HUGO) server -D --disableFastRender

# HUGO_BASEURL env (if set) overrides hugo.toml baseURL for Netlify previews.
build: prepare-docs
	$(HUGO) --minify --destination "$(HUGO_DESTINATION)"

clean:
	rm -rf public resources .cache .hugo_build.lock
