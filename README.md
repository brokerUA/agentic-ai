# Agentic AI Infrastructure

## Prerequisites
- [mise](https://mise.jdx.dev/) installed
- `GEMINI_API_KEY` set in your environment (or `.mise.local.toml` file)

> **Note:** `kubectl` and `helm` are managed by `mise` and will be installed automatically.

## Quick Start (Multi-stage)

To deploy the project step-by-step, use the following `mise` commands:

### Full Deployment
Deploys all stages sequentially (infra -> flux -> apps):
```bash
mise run up
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

## TODO
- Switch to Streamable HTTP instead of SSE for MCP.
- Configure AgentGateway to receive deployment events instead of polling periodically.
