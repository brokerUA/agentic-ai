# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2026-03-23

### Added
- Added `kmcp-crds` for standardizing MCP (Model Control Protocol) server management.

### Changed
- Moved `MCPServer` resource from `kagent` to `kmcp-system` namespace in `platform-agent.yaml` for better infrastructure separation.
- Updated `Agent` tool reference to point to `MCPServer` in the `kmcp-system` namespace.

## [0.1.0] - 2026-03-19

### Added

- Initial project structure for Agentic AI Infrastructure.
- Infrastructure provisioning with OpenTofu (GKE cluster, FluxCD).
- Kubernetes manifests for platform-agent, agentgateway, and kagent components.
- Automated tasks and dependency management using `mise`.
- E2E testing and verification scripts (`scripts/test_agent.sh`, `scripts/verify_agent.sh`).
- CI/CD workflows for AI evaluations and Flux push.

[Unreleased]: https://github.com/brokerUA/agentic-ai/compare/v0.1.1...HEAD
[0.1.0]: https://github.com/brokerUA/agentic-ai/releases/tag/v0.1.0
