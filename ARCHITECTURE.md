# Architecture Overview

## Framework-Core-Service Pattern

```
apps → modules → core → framework → shared
```

### Layers

| Layer | Description | Location |
|-------|-------------|----------|
| **apps** | Runnable entrypoints (Wails, API gateway, microservices) | `apps/` |
| **modules** | Domain-driven feature modules (market, ai, alerts) | `backend/modules/` |
| **core** | Pure business logic, no infrastructure concerns | `backend/core/` |
| **framework** | Reusable infrastructure abstractions (DB, gRPC, messaging) | `backend/framework/` |
| **shared** | Generic types, DTOs, enums, helpers | `backend/shared/` |

### Key Principle

Everything behind interfaces. Frameworks are replaceable.
Swapping Postgres for SQLite should touch only `backend/framework/database/`.

### Communication

- Internal: gRPC (Go ↔ Go, Go ↔ Python)
- Real-time: WebSockets (Go → Svelte)
- Events: NATS (async service communication)
- REST: API Gateway for external clients

### Distribution

Wails compiles Go + Svelte into a single native binary per platform.
