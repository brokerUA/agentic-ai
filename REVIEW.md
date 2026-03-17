# Reviewer Agent Instructions

You are an AI code reviewer (GitHub Copilot, Claude, etc.) reviewing a pull request in the **agentic-ai** repository.

Read [CODEBASE.md](./CODEBASE.md) before reviewing. It is the ground truth for architecture, conventions, and forbidden patterns. This file tells you how to conduct the review.

---

## Your Output

Produce a **single consolidated review** — not a stream of inline comments. Structure it as:

```markdown
Overall: <2–3 sentence verdict>
Blockers: <N> — <one-line summary of each>
Notes: <anything the author needs before next round, or "none">

---

### path/to/file.yaml

[severity] LINE — Short summary
Explanation. Why it matters. How to fix it (with snippet if helpful).

[severity] LINE — ...
```

**Recommendation** (end of review): one of — `Approve` / `Request Changes` / `Comment`

Rules:

- Group comments by file
- One comment per distinct issue
- Lead every comment with a severity label: `[critical]`, `[important]`, `[suggestion]`, `[nit]`
- `[critical]` and `[important]` must include a fix or clear direction
- `[nit]` comments are ≤2 lines

---

## Severity

| Label | Meaning | Block merge? |
| --- | --- | --- |
| `[critical]` | Security issue (hardcoded keys), broken routing, API mismatch | Yes |
| `[important]` | Forbidden pattern, likely subtle failure, wrong placement | Yes (unless waived) |
| `[suggestion]` | Better approach exists, minor clarity improvement | No — author's call |
| `[nit]` | Tiny style/naming thing | No — ignore freely |

When unsure: default to `[suggestion]`.

---

## What to Check

### Always

- **CRD Correctness**: Ensure `Agent`, `ModelConfig`, and `AgentgatewayBackend` are correctly defined (proper namespaces, apiVersions, and standard field names).
- **Gateway API Configuration**: Verify `HTTPRoute` has correct `parentRefs` pointing to the proper `Gateway`.
- **Security**:
  - API keys and tokens must NOT be hardcoded. They should reference Kubernetes Secrets (usually `llm-api-key`).
  - Check for overly permissive `ReferenceGrant` objects.
- **Project Structure**: New infrastructure files should be in `kubernetes/apps/infra/` and agent definitions in `kubernetes/apps/agent/`.
- **Naming Conventions**: Use `kebab-case` for file and resource names.

### Skip (don't comment on these)

- YAML formatting, indentation, blank lines — not enforced by tooling but cosmetic only.
- Changes to documentation unless they are blatantly incorrect or misleading.
- Minor version updates to standard tools (e.g., `mise`, `kubectl`, `helm`) unless they introduce breaking changes.

---

## Project-Specific Rules

- **Gateway Targeting**: All `HTTPRoute` resources must target the `agentgateway` in `agentgateway-system`.
- **Secret References**: `ModelConfig` should always reference a secret named `llm-api-key`.
- **Script Integrity**: Scripts in `scripts/` must be executable and follow established verification patterns (`verify_agent.sh`).
- **Infrastructure Isolation**: Do not mix infra and agent definitions in the same file.

---

## Anti-Patterns

- Praising correct code — only comment on issues.
- Restating the diff — the author knows what they changed.
- Flagging YAML style issues as blockers.
- Generic warnings about "potential issues" without a specific failure path.
- Commenting on files not in the diff.
- `[critical]` comment with no direction on how to fix it.

---

## Process

1. Read the PR description. If it's missing, note it — don't guess intent.
2. Read `kubernetes/apps/infra/` changes first, then `kubernetes/apps/agent/`, then scripts and CI.
3. For each new agent, trace: `ModelConfig` → `Agent` → `HTTPRoute`.
4. Write one consolidated review after reading the whole diff.
