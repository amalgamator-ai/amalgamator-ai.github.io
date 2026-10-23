.PHONY: help init prepare-docs serve build clean

HUGO ?= hugo
HUGO_DESTINATION ?= public
SOURCES_DOCS := sources/amalgamator/docs
VENDOR_DOCS := vendor/docs
CACHE_DOCS := .cache/docs
NAV := data/docs_nav.yaml

help:
	@echo "Targets:"
	@echo "  init           Initialize amalgamator docs submodule"
	@echo "  prepare-docs   Copy product docs and inject Hugo front matter"
	@echo "  serve          Prepare docs and run local Hugo server"
	@echo "  build          Prepare docs and build production site"
	@echo "  clean          Remove generated output and cache"

init:
	GIT_LFS_SKIP_SMUDGE=1 git submodule update --init --recursive sources/amalgamator

# Prefer submodule docs/ when present; otherwise use vendor/docs snapshot
# (product docs are not yet on amalgamator main).
prepare-docs: init
	@test -f "$(NAV)" || (echo "Missing $(NAV)" >&2; exit 1)
	@if [ -f "$(SOURCES_DOCS)/getting-started.md" ]; then \
		SRC="$(SOURCES_DOCS)"; \
	elif [ -f "$(VENDOR_DOCS)/getting-started.md" ]; then \
		SRC="$(VENDOR_DOCS)"; \
		echo "Note: using $(VENDOR_DOCS) (submodule has no docs/ yet)"; \
	else \
		echo "No docs found in $(SOURCES_DOCS) or $(VENDOR_DOCS)" >&2; exit 1; \
	fi; \
	python3 scripts/prepare_docs.py --source "$$SRC" --dest "$(CACHE_DOCS)" --nav "$(NAV)"

serve: prepare-docs
	$(HUGO) server -D --disableFastRender

build: prepare-docs
	$(HUGO) --minify --destination "$(HUGO_DESTINATION)"

clean:
	rm -rf public resources .cache .hugo_build.lock
