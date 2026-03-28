# Questions and Answers about the Agentic AI Infrastructure

This document provides answers to common questions about the current repository's agentic framework (kagent, agentgateway, and mcp-governance).

### 1. How could we handle 'agent got stuck' scenarios?
In this framework, agents are managed as Kubernetes resources. 'Stuck' scenarios are handled at multiple levels:
- **Kubernetes Liveness/Readiness Probes**: The `kagent-controller` and individual agent deployments (for BYO agents) use standard K8s probes to detect and restart unresponsive processes.
- **MCP Timeout Management**: The `MCPServer` CRD and the underlying transport (e.g., SSE/HTTP) allow configuring timeouts for tool calls.
- **Gateway Timeouts**: `agentgateway` (kgateway) enforces global and per-route timeouts for LLM requests.

### 2. Any automatic timeout/circuit breaker patterns coming out from this framework?
Yes, the framework leverages **kgateway** (based on Envoy/Gateway API) which provides:
- **Timeouts**: Configurable at the `HTTPRoute` level in `kubernetes/apps/agentgateway.yaml`.
- **Retries**: Automatic retries for failed model calls.
- **Circuit Breaking**: Envoy-native circuit breakers (max connections, max pending requests) to protect downstream model providers from being overwhelmed.

### 3. How does kgateway handle model failover?
Failover is implemented using **BackendRefs** and **Priority-based Routing** in the Gateway API:
- Multiple model providers (OpenAI, Anthropic, local vLLM) can be defined as backends.
- `agentgateway` can load-balance between them or use a primary-secondary failover strategy where traffic shifts to a backup provider if the primary returns error codes (e.g., 5xx).

### 4. Can we automatically switch from OpenAI to Claude to local model?
Yes. By using the `ModelConfig` CRD and `agentgateway` backends, you can define a unified endpoint. If the primary provider (e.g., OpenAI) fails or hits rate limits, the gateway can automatically reroute the request to Anthropic (Claude) or a local vLLM instance. This is transparent to the agent as it always talks to the `agentgateway` internal URL.

### 5. Could we seamlessly handle the response formats from these providers?
Yes. `agentgateway` acts as an **AI Protocol Transformer**. It exposes an OpenAI-compatible API (as seen in `platform-agent.yaml` pointing to `baseUrl: .../v1`) and handles the internal translation to specific provider formats (Gemini, Anthropic, etc.), ensuring the agent receives a consistent response format regardless of the backend.

### 6. Can we version the agents built from kagent?
Yes, versioning is integrated into the GitOps workflow:
- **Git/Flux Versioning**: Using `OCIRepository` and `HelmRelease` (in `kagent.yaml`), agents are versioned via tags and semver.
- **K8s Metadata**: Each `Agent` resource can have labels and annotations for version tracking.
- **Image Tags**: For BYO agents, the container image tag provides a clear versioning mechanism.

### 7. Any blue/green or canary deployment patterns for agents?
Yes, since agents are K8s resources, we can use:
- **Argo Rollouts**: Mentioned as a potential tool in `kagent.yaml` (though currently disabled).
- **Gateway API Weighting**: `HTTPRoute` backends can have weights (e.g., 90% to `v1-agent`, 10% to `v2-agent`) to perform canary releases.
- **Flux Flagger**: Can automate canary analysis and promotion for agent deployments.

### 8. What's the fastmcp-python framework mentioned?
In the context of this repository, we strictly use the **Google ADK (Agent Development Kit)** for agent and tool orchestration. While `fastmcp-python` is a popular community framework for rapid MCP server development, this infrastructure is built upon Google's ADK to ensure enterprise-grade stability, native Gemini integration, and seamless scaling within the Kubernetes environment.

### 9. Is it the easiest path to mcp?
Yes, using Google's ADK provides the most streamlined experience for this specific infrastructure. It abstracts the complexities of the Model Context Protocol, allowing developers to define tools and agents using high-level Python patterns that are natively understood by the `kagent` controller and `agentgateway`.

### 10. About finops: how much control I can have?
The `mcp-governance` component (found in `charts/mcp-governance`) provides extensive FinOps controls through the `MCPGovernancePolicy` CRD.

### 11. Token level / per agent level
Controls are available at both levels:
- **Per-Agent**: Policies can be applied to specific namespaces or target agents.
- **Token Level**: `agentgateway` can track and limit token usage per API key or per route.

### 12. Can I implement custom cost controls?
Yes. The `MCPGovernancePolicy` allows setting:
- **Rate Limits**: Requests per minute/hour.
- **Tool Usage Limits**: `maxToolsWarning` and `maxToolsCritical` thresholds to prevent expensive "agent loops".
- **Scoring Weights**: You can penalize or block agents based on security and cost metrics.

### 13. Per-agent budgets or depth of Token limits
The framework supports:
- **Budgeting**: By integrating with external billing/quota systems via `agentgateway` metadata.
- **Token Depth**: Limits on total tokens per session to prevent infinite recursion or excessive context usage.

### 14. vLLM suitable for agents with many back and forth tool calls, or is it better for single shot inference?
vLLM is highly suitable for multi-turn agent interactions because of its **PagedAttention** mechanism, which efficiently manages KV caches. This significantly reduces latency in "back and forth" tool calls compared to standard inference engines that might re-process the entire prompt history.

### 15. llm-d's scheduler - helps when agents makes 15 llms calls?
Yes. A specialized LLM scheduler (like those in `llm-d` or `vLLM`) helps by:
- **Request Batching**: Grouping multiple agent calls together.
- **Prefix Caching**: Since 15 calls from the same agent likely share the same system prompt and history, prefix caching avoids redundant computation, drastically speeding up sequential tool-use loops.
