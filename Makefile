SHELL := /bin/sh
.ONESHELL:
.SHELLFLAGS: -euo
.DEFAULT_GOAL: help
.NOTPARALLEL:
.POSIX:

#

CMAKE ?= cmake
RM = $(CMAKE) -E rm -rf

BUILDS ?= Builds
CACHE ?= Cache

#

override REPO_ROOT = $(patsubst %/,%,$(strip $(dir $(realpath $(firstword $(MAKEFILE_LIST))))))

#

.PHONY: help
help:  ## Print this message
	@grep -E '^[a-zA-Z_-]+:.*?\#\# .*$$' $(REPO_ROOT)/Makefile | sort | awk 'BEGIN {FS = ":.*?\#\# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#

$(BUILDS):
	$(CMAKE) -S $(REPO_ROOT) -B $(REPO_ROOT)/$(BUILDS)

.PHONY: config
config: $(BUILDS) ## configure CMake

#

.PHONY: build
build: config ## runs CMake build
	$(CMAKE) --build $(REPO_ROOT)/$(BUILDS)

#

.PHONY: clean
clean: ## Cleans the source tree
	@echo "Cleaning..."
	$(RM) $(REPO_ROOT)/$(BUILDS)
