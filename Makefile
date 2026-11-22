BINARY  := zvtop
PKG     := ./cmd/zvtop
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
LDFLAGS := -s -w -X main.version=$(VERSION)

# go-nvml's bundled headers mark several unused symbols deprecated.
export CGO_CFLAGS ?= -Wno-deprecated-declarations

.DEFAULT_GOAL := help
.PHONY: help all build run demo test cover lint fmt clean install deps

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

all: lint test build ## Lint, test and build

# Download Go module deps and install golangci-lint if it's missing.
deps: ## Install Go (if missing), download modules, install golangci-lint
	./scripts/install-go.sh
	go mod download
	go mod verify
	@command -v golangci-lint >/dev/null 2>&1 || \
		go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest

build: ## Build ./bin/zvtop
	go build -trimpath -ldflags '$(LDFLAGS)' -o bin/$(BINARY) $(PKG)

install: ## go install the binary
	go install -trimpath -ldflags '$(LDFLAGS)' $(PKG)

run: build ## Build and run
	./bin/$(BINARY)

demo: build ## Run against two simulated GPUs
	./bin/$(BINARY) -mock 2

test: ## Run tests with -race
	go test -race -count=1 ./...

cover: ## Run tests with coverage summary
	go test -race -coverprofile=coverage.out ./...
	go tool cover -func=coverage.out | tail -1

lint: ## Run golangci-lint
	golangci-lint run ./...

fmt: ## Format with golangci-lint
	golangci-lint fmt ./...

clean: ## Remove build artifacts
	rm -rf bin coverage.out dist
