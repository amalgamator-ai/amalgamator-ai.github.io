.PHONY: help init fetch-docs prepare-docs prepare-community prepare serve build clean

HUGO ?= hugo
HUGO_DESTINATION ?= public
SOURCES_ROOT := sources/amalgamator
SOURCES_DOCS := $(SOURCES_ROOT)/docs
CACHE_SRC := .cache/amalgamator-src
CACHE_DOCS := .cache/docs
CACHE_COMMUNITY := .cache/community
CACHE_DATA := .cache/data
AMALGAMATOR_REF ?= main
# Optional override for CI / docs PR previews (path to amalgamator docs/)
DOCS_SOURCE ?=

help:
	@echo "Targets:"
	@echo "  init               Initialize amalgamator git submodule (optional local path)"
	@echo "  fetch-docs         Shallow-fetch public amalgamator docs into .cache/"
	@echo "  prepare-docs       Copy product docs + nav; inject Hugo front matter"
	@echo "  prepare-community  Copy CONTRIBUTING / CoC / SECURITY into content"
	@echo "  prepare            prepare-docs + prepare-community"
	@echo "  serve              Prepare content and run local Hugo server"
	@echo "  build              Prepare content and build production site"
	@echo "  clean              Remove generated output and cache"

init:
	@if [ -e $(SOURCES_ROOT)/.git ] || [ -f $(SOURCES_ROOT)/README.md ]; then \
		echo "$(SOURCES_ROOT) already present"; \
	else \
		GIT_LFS_SKIP_SMUDGE=1 git submodule update --init --recursive $(SOURCES_ROOT); \
	fi

fetch-docs:
	@chmod +x scripts/fetch_amalgamator_docs.sh
	scripts/fetch_amalgamator_docs.sh "$(AMALGAMATOR_REF)" "$(CACHE_SRC)"

prepare-docs: init
	@set -e; \
	if [ -n "$(DOCS_SOURCE)" ] && [ -f "$(DOCS_SOURCE)/getting-started.md" ]; then \
		SRC="$(DOCS_SOURCE)"; \
	elif [ -f "$(SOURCES_DOCS)/getting-started.md" ]; then \
		SRC="$(SOURCES_DOCS)"; \
	else \
		$(MAKE) fetch-docs; \
		SRC="$(CACHE_SRC)/docs"; \
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

prepare-community: init
	@set -e; \
	if [ -n "$(DOCS_SOURCE)" ] && [ -f "$(DOCS_SOURCE)/../CONTRIBUTING.md" ]; then \
		ROOT="$(DOCS_SOURCE)/.."; \
	elif [ -f "$(CACHE_SRC)/CONTRIBUTING.md" ]; then \
		ROOT="$(CACHE_SRC)"; \
	elif [ -f "$(SOURCES_ROOT)/CONTRIBUTING.md" ]; then \
		ROOT="$(SOURCES_ROOT)"; \
	else \
		$(MAKE) fetch-docs; \
		ROOT="$(CACHE_SRC)"; \
	fi; \
	echo "Preparing community pages from $$ROOT"; \
	python3 scripts/prepare_community.py --source "$$ROOT" --dest "$(CACHE_COMMUNITY)"

prepare: prepare-docs prepare-community

serve: prepare
	$(HUGO) server -D --disableFastRender

# HUGO_BASEURL env (if set) overrides hugo.toml baseURL for Netlify previews.
build: prepare
	$(HUGO) --minify --destination "$(HUGO_DESTINATION)"

clean:
	rm -rf public resources .cache .hugo_build.lock
