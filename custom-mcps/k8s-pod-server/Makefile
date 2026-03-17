# Variables
IMAGE_NAME ?= k8s-pod-mcp-server
IMAGE_TAG ?= latest
# For local kind development without registry prefix
FULL_IMAGE_NAME = $(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: build
build:
	docker build -t $(FULL_IMAGE_NAME) src/

.PHONY: kind-load
kind-load:
	kind load docker-image $(FULL_IMAGE_NAME) --name andreev-agentic-ai

.PHONY: all
all: build push
