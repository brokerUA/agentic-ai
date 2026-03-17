# Agentic AI Infrastructure

Lab-1: Deploying Basic Agentic Infrastructure (Level: **MAX**).

This project implements a Kubernetes-native agentic infrastructure using `agentgateway` (in KGway mode with **Kubernetes Gateway API**) and `kagent`.

### Solution Level: MAX
- **AgentGateway (KGway mode)**: Fully integrated with Kubernetes Gateway API (`Gateway`, `HTTPRoute`, `AgentgatewayBackend`).
- **Secrets & ConfigMaps**: All sensitive data and configurations are managed natively.
- **KAgent**: Controller and agents are deployed and configured to route via the local gateway.
- **Built-in Agents**: Configured `default-model-config` to allow built-in agents to work through the local gateway.

## Prerequisites
- [mise](https://mise.jdx.dev/) installed
- `GEMINI_API_KEY` set in your environment (or `.mise.local.toml` file)

> **Note:** `kubectl` and `helm` are managed by `mise` and will be installed automatically.

## Quick Start (Step-by-Step)

[![asciicast](https://asciinema.org/a/gPaFWMnjKn1xSLgj.svg)](https://asciinema.org/a/gPaFWMnjKn1xSLgj)

Follow these steps in order using `mise`:

1.  **Install Gateway API CRDs:**
    ```bash
    mise run install-gateway-api
    ```
2.  **Deploy AgentGateway (KGway mode):**
    ```bash
    mise run deploy-agentgateway
    ```
3.  **Deploy Infrastructure (Secret, ConfigMap, Route):**
    ```bash
    mise run deploy-infra
    ```
4.  **Install KAgent Controller:**
    ```bash
    mise run install-kagent
    ```
5.  **Deploy Agent and ModelConfig:**
    ```bash
    mise run deploy-agent
    ```

## Verification

To ensure everything is working correctly, run:

1.  **Basic Infrastructure Check:**
    ```bash
    mise run verify
    ```
2.  **End-to-End Agent Test:**
    ```bash
    mise run test-agent
    ```
3.  **Check Built-in Agents:**
    ```bash
    kubectl get agent -n kagent
    ```
    (Ensure `k8s-agent` and others are in `Ready` state)

## Project Structure
- `infra/`: Gateway and AI provider configurations.
- `agent/`: Declarative agent definitions.
- `scripts/`: Verification and testing scripts.
