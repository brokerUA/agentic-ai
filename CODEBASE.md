# Codebase Documentation for AI Agent

## Project Summary

This project implements a Kubernetes-native agentic infrastructure using `agentgateway` (in KGway mode with **Kubernetes Gateway API**) and `kagent`. It provides a way to deploy and manage AI agents and their model configurations as Kubernetes resources.

## Architecture

- **AgentGateway (KGway mode)**: Fully integrated with Kubernetes Gateway API (`Gateway`, `HTTPRoute`, `AgentgatewayBackend`). It acts as a gateway for routing AI requests to various providers.
- **KAgent**: Controller and agents are deployed to manage the lifecycle of AI agents within the cluster.
- **Infrastructure Layer**: Uses standard Kubernetes objects (Secret, ConfigMap, ReferenceGrant) alongside Custom Resource Definitions (CRDs) from `agentgateway` and `kagent`.

## Package Structure

- `infra/`: Contains Kubernetes manifests for the AI infrastructure, including Gateway, HTTPRoute, AgentgatewayBackend, and provider configurations.
- `agent/`: Contains declarative definitions for AI agents (`Agent`) and model configurations (`ModelConfig`).
- `scripts/`: Utility scripts for verifying and testing the deployed infrastructure.
- `.github/workflows/`: CI/CD pipelines, including the newly implemented AI PR instrumentation.

## Main Domain Types (CRDs)

- `Agent`: Defines an AI agent's behavior and associated model configuration.
- `ModelConfig`: Configures the LLM provider, model, and authentication for agents.
- `AgentgatewayBackend`: Defines how `agentgateway` should route and process AI requests (e.g., Gemini).
- `Gateway`, `HTTPRoute`: Standard Kubernetes Gateway API resources used for routing.

## Naming Conventions

- Kubernetes manifests use `kebab-case` for file names (e.g., `basic-agent.yaml`).
- Resource names within manifests also follow `kebab-case`.
- Namespaces are consistently used: `agentgateway-system` for the gateway and `kagent` for the agents.

## Code Patterns

- **Declarative Management**: All infrastructure and agent configurations are managed as YAML manifests.
- **Gateway API Integration**: Using `HTTPRoute` with `parentRefs` to link routes to the `Gateway`.
- **Secret Management**: API keys and sensitive data are handled via Kubernetes `Secrets` and referenced in `ModelConfig` or `AgentgatewayBackend`.
