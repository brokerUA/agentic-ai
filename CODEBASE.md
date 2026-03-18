# AI Agent Codebase Documentation

## Project Overview

This project implements a Kubernetes-based cloud infrastructure for AI agents using `agentgateway` (in KGway mode with **Kubernetes Gateway API**) and `kagent`. It allows deploying AI agents and their configurations as standard Kubernetes resources.

## Architecture

- **AgentGateway (KGway mode)**: Fully integrated with the Kubernetes Gateway API (`Gateway`, `HTTPRoute`, `AgentgatewayBackend`). It acts as a gateway for routing requests to various LLM providers.
- **KAgent**: Controller and agents managing the lifecycle of AI agents within the cluster.
- **Infrastructure Layer**: Uses standard Kubernetes objects (Secret, ConfigMap, ReferenceGrant) alongside Custom Resource Definitions (CRDs) from `agentgateway` and `kagent`.

## Project Structure

- `kubernetes/apps/`: Contains Kubernetes application manifests, including `agentgateway.yaml`, `kagent.yaml`, `infra.yaml` (secrets, routing), and `platform-agent.yaml`.
- `kubernetes/crds/`: Contains Custom Resource Definitions (CRDs) for `agentgateway`, `kagent`, and the Gateway API.
- `infrastructure/bootstrap/`: Terraform configurations for provisioning cloud infrastructure and Flux CD.
- `scripts/`: Utilities for testing and verifying the deployed infrastructure.
- `.github/workflows/`: CI/CD pipelines for Flux CD and repository automation.
- `.mise/tasks/`: Custom `mise` tasks for project setup and deployment.

## Core Domain Types (CRDs)

- `Agent`: Defines AI agent behavior and associated model configuration.
- `ModelConfig`: Configures the LLM provider, model, and authentication for agents.
- `MCPServer`: (KAgent CRD) Describes a Model Context Protocol server to provide tools to agents.
- `AgentgatewayBackend`: Defines how `agentgateway` should route and process AI requests (e.g., Gemini).
- `Gateway`, `HTTPRoute`: Standard Kubernetes Gateway API resources used for routing.

## Naming Conventions

- Kubernetes manifests use `kebab-case` for filenames (e.g., `platform-agent.yaml`).
- Resource names within manifests also follow `kebab-case`.
- Namespaces are used consistently: `agentgateway-system` for the gateway and `kagent` for the agents.

## Code Patterns

- **Declarative Management**: All infrastructure and agent configurations are managed as YAML manifests.
- **Gateway API Integration**: Use of `HTTPRoute` with `parentRefs` to bind routes to a `Gateway`.
- **Secret Management**: API keys and sensitive data are handled via Kubernetes `Secret` resources and referenced in `ModelConfig` or `AgentgatewayBackend`.
- **Tools**: Use of MCP (Model Context Protocol) to extend agent capabilities via external servers.
