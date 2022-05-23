SHELL := /bin/sh
.ONESHELL:
.SHELLFLAGS: -euo
.DEFAULT_GOAL: help
.NOTPARALLEL:
.POSIX:

#

CMAKE ?= cmake
RM = $(CMAKE) -E rm -rf
PRECOMMIT ?= pre-commit
GIT ?= git

BUILDS ?= Builds
CACHE ?= Cache

#

override REPO_ROOT = $(patsubst %/,%,$(strip $(dir $(realpath $(firstword $(MAKEFILE_LIST))))))

#

.PHONY: help
help:  ## Print this message
	@grep -E '^[a-zA-Z_-]+:.*?\#\# .*$$' $(REPO_ROOT)/Makefile | sort | awk 'BEGIN {FS = ":.*?\#\# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

#

.PHONY: init
init:  ## Initializes the workspace and installs all dependencies
	@cd $(REPO_ROOT) && \
		$(PRECOMMIT) install --install-hooks --overwrite && \
		$(PRECOMMIT) install --install-hooks --overwrite --hook-type commit-msg

#

$(BUILDS):
	@cd $(REPO_ROOT) && $(CMAKE) -B $(BUILDS)

.PHONY: config
config: $(BUILDS) ## configure CMake

#

.PHONY: build
build: config ## runs CMake build
	@cd $(REPO_ROOT) && $(CMAKE) --build $(BUILDS)

#

.PHONY: pc
pc:  ## Runs all pre-commit hooks over all files
	@cd $(REPO_ROOT) && $(GIT) add . && $(PRECOMMIT) run --all-files

#

.PHONY: clean
clean: ## Cleans the source tree
	@echo "Cleaning..."
	@cd $(REPO_ROOT) && $(RM) $(BUILDS); $(PRECOMMIT) gc
