# AuraMind AI — Agent Guide

> **Source of Truth:** Always read `project.md` first before any development work.
>
> **Stack:** Svelte + Go + Wails (Desktop-First) | gRPC internal comms | Python AI services
>
> **Distribution:** Single native binary per platform (`.exe` / `.dmg` / `.AppImage`)

---

## 1. Architecture Pattern: Framework-Core-Service

```
┌─────────────────────────────────────────────────────┐
│                    apps/                             │
│  (desktop, api-gateway, market, ai, alert, worker)  │
├─────────────────────────────────────────────────────┤
│                    modules/                          │
│  (market, ai, whale, alerts, risk, auth, portfolio) │
├──────────────────────────┬──────────────────────────┤
│        core/             │       framework/          │
│  (pure business logic)   │  (reusable infra layer)   │
├──────────────────────────┴──────────────────────────┤
│                    shared/                           │
│       (types, dto, enums, helpers, events)           │
└─────────────────────────────────────────────────────┘
```

### Dependency Rules (ABSOLUTE)
```
apps       → modules
modules    → core       + framework + shared
core       → framework  + shared
framework  → shared
shared     → (nothing)
```

> **Golden Rule:** Never import a `module` from another `module`. Never import `core` from `framework`. Dependencies flow DOWN only.

---

## 2. Full Directory Tree

```
auramind/
│
├── apps/                              # Entrypoints (independently runnable)
│   ├── desktop/                       # Wails desktop app (main.go + app.go)
│   │   ├── main.go
│   │   ├── app.go                     # Go ↔ Svelte bindings
│   │   └── wails.json
│   ├── api-gateway/                   # REST API gateway
│   │   └── main.go
│   ├── market-service/                # Market ingestion service
│   │   └── main.go
│   ├── ai-service/                    # Go wrapper for Python AI
│   │   └── main.go
│   ├── alert-service/                 # Notification/dispatch service
│   │   └── main.go
│   ├── strategy-service/              # Backtesting engine service
│   │   └── main.go
│   └── worker/                        # Background job runner
│       └── main.go
│
├── frontend/                          # Svelte + Vite + Tailwind
│   ├── src/
│   │   ├── app/
│   │   │   ├── routes/
│   │   │   ├── layouts/
│   │   │   └── providers/
│   │   │
│   │   ├── components/
│   │   │   ├── ui/                    # Primitive UI (buttons, inputs, cards)
│   │   │   ├── charts/               # TradingView, Chart.js wrappers
│   │   │   ├── dashboard/            # Dashboard-specific widgets
│   │   │   ├── trading/              # Trade panels, order forms
│   │   │   └── shared/              # Cross-feature reusable components
│   │   │
│   │   ├── modules/                  # Feature-based frontend modules
│   │   │   ├── auth/                 # Login, register, session
│   │   │   ├── market/              # Price charts, order book
│   │   │   ├── whale/               # Whale tracking UI
│   │   │   ├── ai/                  # AI insights, chat, analysis
│   │   │   ├── alerts/              # Alert management
│   │   │   └── portfolio/           # Portfolio tracker
│   │   │
│   │   ├── services/                 # API/gRPC client wrappers
│   │   ├── stores/                   # Svelte reactive stores
│   │   ├── hooks/                    # Svelte actions/hooks
│   │   ├── lib/                      # Third-party library configs
│   │   ├── types/                    # TypeScript interfaces
│   │   ├── constants/                # App-wide constants
│   │   ├── utils/                    # Utility functions
│   │   └── styles/                   # Global styles
│   │
│   ├── static/
│   ├── package.json
│   ├── svelte.config.js
│   └── vite.config.ts
│
├── backend/                           # All Go code
│   ├── cmd/                          # Binary entrypoints (alternative to apps/)
│   │   ├── api/
│   │   ├── market/
│   │   ├── alerts/
│   │   ├── strategy/
│   │   └── worker/
│   │
│   ├── core/                         # Pure business logic ONLY
│   │   ├── market/
│   │   ├── ai/
│   │   ├── indicators/
│   │   ├── whale/
│   │   ├── alerts/
│   │   ├── portfolio/
│   │   └── strategy/
│   │
│   ├── framework/                    # Reusable infrastructure (THE KEY LAYER)
│   │   ├── database/
│   │   │   ├── postgres/
│   │   │   ├── sqlite/
│   │   │   ├── clickhouse/
│   │   │   ├── redis/
│   │   │   ├── migrations/
│   │   │   ├── repositories/
│   │   │   └── interfaces/          # DB-agnostic repository interfaces
│   │   │
│   │   ├── grpc/
│   │   │   ├── client/
│   │   │   ├── server/
│   │   │   ├── interceptors/
│   │   │   ├── middleware/
│   │   │   ├── proto/               # .proto definitions
│   │   │   └── generated/           # Generated protobuf code
│   │   │
│   │   ├── websocket/
│   │   ├── messaging/
│   │   │   ├── nats/
│   │   │   ├── kafka/
│   │   │   └── interfaces/
│   │   │
│   │   ├── logging/
│   │   ├── config/                   # Config loader (Viper-based)
│   │   ├── cache/
│   │   ├── auth/                     # JWT, OAuth, RBAC
│   │   ├── monitoring/               # Prometheus metrics
│   │   ├── security/                 # Encryption, sanitization
│   │   ├── validation/
│   │   └── errors/                   # Standardized error types
│   │
│   ├── modules/                      # Domain-driven modules
│   │   ├── market/                   # Each module has:
│   │   │   ├── handler.go            #   - HTTP/gRPC handler
│   │   │   ├── service.go            #   - Business logic service
│   │   │   ├── repository.go         #   - Repository interface
│   │   │   ├── dto.go                #   - Data transfer objects
│   │   │   ├── model.go              #   - Domain model
│   │   │   └── events.go             #   - Domain events
│   │   ├── ai/
│   │   ├── whale/
│   │   ├── alerts/
│   │   ├── risk/
│   │   ├── auth/
│   │   └── portfolio/
│   │
│   ├── shared/                       # Generic reusable code
│   │   ├── constants/
│   │   ├── dto/                      # Cross-module DTOs
│   │   ├── enums/
│   │   ├── helpers/
│   │   ├── utils/
│   │   ├── types/
│   │   └── events/                   # Event type definitions
│   │
│   ├── tests/
│   │   ├── integration/
│   │   ├── e2e/
│   │   └── mocks/
│   │
│   ├── scripts/
│   │   ├── generate-proto.sh
│   │   ├── migrate.sh
│   │   ├── seed.sh
│   │   └── dev.sh
│   │
│   ├── go.mod
│   └── go.sum
│
├── services/                          # Non-Go runtimes
│   ├── python-ai/                    # FastAPI + LangChain + LLMs
│   │   ├── app/
│   │   ├── models/
│   │   ├── pipelines/
│   │   ├── prompts/
│   │   ├── embeddings/
│   │   ├── vector/
│   │   ├── api/
│   │   ├── tests/
│   │   └── requirements.txt
│   │
│   └── sentiment-engine/            # NLP sentiment pipeline
│       ├── app/
│       └── requirements.txt
│
├── deployments/
│   ├── docker/
│   ├── kubernetes/
│   ├── terraform/
│   └── github-actions/
│
├── docs/
│   ├── architecture/
│   ├── api/                          # REST API docs
│   ├── grpc/                         # gRPC service docs
│   ├── setup/                        # Setup guides
│   ├── workflows/                    # Dev workflows
│   └── diagrams/
│
├── tools/
│   ├── auractl.sh                    # Quick-start bash menu (portable)
│   │
│   └── cli/                          # Go-based CLI (future)
│       ├── main.go
│       ├── menu/
│       ├── commands/
│       ├── builders/
│       ├── installers/
│       └── environments/
│
├── configs/
│   ├── app/
│   ├── database/
│   ├── environments/
│   │   ├── development.yaml
│   │   ├── staging.yaml
│   │   └── production.yaml
│   └── feature-flags/
│
├── build/                            # Build artifacts (gitignored)
│   ├── windows/
│   ├── mac/
│   └── linux/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
│
├── project.md                        # Project specification (source of truth)
├── AGENTS.md                         # THIS FILE — build guide & conventions
├── Makefile
├── Taskfile.yml
├── docker-compose.yml
├── go.work                           # Go workspace file
├── README.md
├── CONTRIBUTING.md
├── ARCHITECTURE.md
└── LICENSE
```

---

## 3. Framework Layer — The Most Important Part

Instead of scattered `utils/db.go` files, all infrastructure lives in `framework/` with clean interfaces and multiple implementations.

### 3.1 Database Framework

```
framework/database/
├── interfaces/            # DB-agnostic repository interfaces
│   └── user_repository.go
├── postgres/              # PostgreSQL implementations
│   └── user_repository.go
├── sqlite/                # SQLite implementations (desktop mode)
│   └── user_repository.go
├── clickhouse/            # Time-series implementations
├── redis/                 # Cache/pub-sub implementations
├── migrations/            # SQL migration files
└── repositories/          # Generic repository base
```

**Pattern:**
```go
// framework/database/interfaces/user_repository.go
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    GetByID(ctx context.Context, id string) (*User, error)
    Update(ctx context.Context, user *User) error
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter UserFilter) ([]*User, error)
}
```

```go
// framework/database/postgres/user_repository.go
type PostgresUserRepository struct {
    db *sql.DB
}

func (r *PostgresUserRepository) Create(ctx context.Context, user *User) error {
    // PostgreSQL-specific SQL
}

// framework/database/sqlite/user_repository.go
type SQLiteUserRepository struct {
    db *sql.DB
}

func (r *SQLiteUserRepository) Create(ctx context.Context, user *User) error {
    // SQLite-specific SQL
}
```

> **Benefit:** Switching from Postgres to SQLite (or vice versa) requires ONE line change during wiring.

### 3.2 gRPC Framework

```
framework/grpc/
├── client/
│   └── client.go          # Generic gRPC client base
├── server/
│   └── server.go          # Generic gRPC server base
├── interceptors/
│   ├── logging.go
│   ├── auth.go
│   └── recovery.go
├── middleware/
├── proto/                 # All .proto files
└── generated/             # Generated Go code
```

**Generic Service Interface:**
```go
// framework/grpc/server/service.go
type Service[T any] interface {
    Create(ctx context.Context, item T) (*T, error)
    Get(ctx context.Context, id string) (*T, error)
    Update(ctx context.Context, item T) (*T, error)
    Delete(ctx context.Context, id string) error
    List(ctx context.Context, filter map[string]any) ([]*T, error)
}
```

**Generic Response:**
```protobuf
// framework/grpc/proto/common.proto
message ApiResponse {
  bool success = 1;
  string message = 2;
  google.protobuf.Any data = 3;
  int32 error_code = 4;
}
```

### 3.3 Messaging Framework

```
framework/messaging/
├── interfaces/
│   ├── publisher.go
│   └── subscriber.go
├── nats/
│   ├── publisher.go
│   └── subscriber.go
└── kafka/
    ├── publisher.go
    └── subscriber.go
```

---

## 4. Go Coding Conventions

### 4.1 Module Structure (Every Feature is a Module)

Each module in `modules/` follows this exact pattern:

```
modules/market/
├── handler.go            # HTTP/gRPC handlers (thin — delegates to service)
├── service.go            # Business logic (all decisions here)
├── repository.go         # Repository interface (defined here, implemented in framework)
├── dto.go                # Request/response DTOs
├── model.go              # Domain model (DB-agnostic)
└── events.go             # Domain events for messaging
```

### 4.2 Key Rules

| Rule | Description |
|------|-------------|
| Handlers are thin | No business logic in handlers — delegate to service |
| Everything on interfaces | Accept interfaces, return structs |
| Frameworks are replaceable | DB, messaging, cache — all behind interfaces |
| No circular imports | Dependencies flow DOWN only |
| Errors are typed | Use `framework/errors/` for standard error types |
| Config is injected | Use Viper — never hardcode |
| Logging is structured | Use Zap — never use `log.Println` |

### 4.3 Recommended Go Packages

| Purpose | Package | Why |
|---------|---------|-----|
| Config | `github.com/spf13/viper` | YAML/env config loading |
| CLI | `github.com/spf13/cobra` | CLI commands |
| Logging | `go.uber.org/zap` | Structured, performant |
| DI | `github.com/google/wire` or `go.uber.org/fx` | Dependency injection |
| Validation | `github.com/go-playground/validator/v10` | Struct validation |
| ORM | `gorm.io/gorm` or `github.com/sqlc-dev/sqlc` | DB access |
| Migrations | `github.com/pressly/goose` | SQL migrations |
| gRPC | `google.golang.org/grpc` | RPC framework |
| Auth | `github.com/golang-jwt/jwt/v5` | JWT tokens |
| Testing | `github.com/stretchr/testify` | Assertions + mocks |

### 4.4 gRPC Code Generation

All `.proto` files go in `framework/grpc/proto/`. Generated code goes in `framework/grpc/generated/`.

Run via script:
```bash
backend/scripts/generate-proto.sh
```

---

## 5. Frontend Conventions (Svelte)

### 5.1 Component Hierarchy

```
components/
├── ui/              # Primitive: Button, Input, Modal, Card, Badge
├── charts/          # Chart wrappers: PriceChart, VolumeChart, IndicatorChart
├── dashboard/       # Dashboard panels: MarketOverview, TopMovers, NewsFeed
├── trading/         # Trade panels: OrderForm, PositionCard, TradeHistory
└── shared/          # Cross-feature: Loading, Error, Empty states
```

### 5.2 Store Pattern

Use Svelte's built-in writable/derived stores:
```
stores/
├── market.ts        # Current prices, selected pair
├── auth.ts          # Session, user state
├── alerts.ts        # Active alerts
├── portfolio.ts     # Portfolio state
└── ai.ts            # AI analysis results
```

### 5.3 gRPC Client Integration

Frontend never calls databases directly. All data flows through gRPC clients:
```
services/
├── grpc.ts          # gRPC client initialization
├── market.ts        # MarketService client
├── ai.ts            # AIService client
└── alerts.ts        # AlertService client
```

---

## 6. Development CLI — `auractl`

### 6.1 Quick Start (Bash Script)

`tools/auractl.sh` is the **portable entry point** that anyone (even non-Go devs) can run immediately after cloning.

**Run it:**
```bash
bash tools/auractl.sh
```

**Menu:**
```
╔══════════════════════════════════════╗
║        AuraMind Developer Toolkit    ║
╠══════════════════════════════════════╣
║  1)  Run Desktop App (Wails)         ║
║  2)  Run All Backend Services        ║
║  3)  Run AI Service (Python)         ║
║  4)  Run Full Stack                  ║
║  5)  Build Windows .exe              ║
║  6)  Build Mac .dmg                  ║
║  7)  Build Linux .AppImage           ║
║  8)  Generate gRPC Code              ║
║  9)  Run DB Migrations               ║
║ 10)  Seed Database                   ║
║ 11)  Run All Tests                   ║
║ 12)  Docker Build                    ║
║ 13)  Kubernetes Deploy               ║
║ 14)  Clean Build                     ║
║ 15)  Install All Dependencies        ║
║ 16)  Setup Dev Environment           ║
║  0)  Exit                            ║
╚══════════════════════════════════════╝
```

### 6.2 Future: Go-Based CLI

The bash script is the starting point. For feature-rich operations, a Go CLI lives in `tools/cli/` using Cobra:

```bash
auractl dev                    # Start development environment
auractl build windows          # Build Windows binary
auractl build mac              # Build macOS binary
auractl proto generate         # Generate gRPC stubs
auractl db migrate             # Run migrations
auractl db seed                # Seed data
auractl docker up              # Docker compose up
auractl test                   # Run all tests
auractl setup                  # First-time setup
```

---

## 7. Setup & Onboarding

### 7.1 Prerequisites

```
- Go 1.22+
- Node.js 20+
- Wails CLI (go install github.com/wailsapp/wails/v2/cmd/wails@latest)
- Python 3.11+
- Docker (optional)
```

### 7.2 Quick Start (From Clone to Running)

```bash
# 1. Clone
git clone https://github.com/AkashKumbhar07/auramind.git
cd auramind

# 2. Run setup
bash tools/auractl.sh
# → Option 16: Setup Dev Environment

# 3. Run desktop app
# → Option 1: Run Desktop App
```

### 7.3 Environment Configuration

All environment configs live in `configs/environments/`:
```
configs/environments/
├── development.yaml     # Local dev defaults
├── staging.yaml         # Staging environment
└── production.yaml      # Production environment
```

Configs are loaded by `framework/config/` using Viper. The active environment is selected via `APP_ENV` env variable.

---

## 8. Agent Instructions (Meta Rules for AI & Contributors)

### 8.1 Always Do

1. **Read `project.md`** before any feature work — it defines the project scope
2. **Check AGENTS.md** for architecture conventions before writing any code
3. **Write interfaces first** — define the contract before the implementation
4. **Place code in the right layer** — business logic in `core/`, infra in `framework/`, glue in `modules/`, entrypoints in `apps/`
5. **Keep handlers thin** — parse request, call service, return response — nothing else
6. **Use framework abstractions** — never use a DB driver directly in a module
7. **Add tests** — unit tests for `core/`, integration tests for `modules/`, e2e for `apps/`

### 8.2 Never Do

1. **No business logic in handlers** — that's what `core/` is for
2. **No direct DB access from modules** — use repository interfaces from `framework/database/interfaces/`
3. **No circular imports** — dependency direction is absolute
4. **No hardcoded config** — everything in `configs/`, loaded via `framework/config/`
5. **No module→module imports** — modules communicate via events or the shared kernel
6. **No `utils/` or `helpers/` dumping ground** — everything has a named home in `framework/`, `shared/`, or `core/`
7. **No framework coupling** — all frameworks sit behind interfaces; swapping NATS for Kafka should touch only `framework/messaging/`

### 8.3 Build Order (Phases)

```
Phase 1: Foundation
├── Project spec (project.md) ✓ DONE
├── Architecture guide (AGENTS.md) ✓ DONE
├── Directory structure scaffold
├── Framework layer (database, grpc, config, logging)
└── CLI tool (auractl.sh)

Phase 2: Core
├── Database implementations (postgres, sqlite)
├── gRPC proto definitions + generation
├── Market ingestion service
├── Indicator engine
└── Authentication module

Phase 3: Frontend
├── Svelte scaffold + Tailwind setup
├── UI component library
├── Dashboard layout
├── Market charts
└── gRPC client integration

Phase 4: AI Integration
├── Python AI service (FastAPI + LangChain)
├── Sentiment engine
├── Whale tracking
└── AI insights module

Phase 5: Desktop
├── Wails binding setup
├── Go ↔ Svelte integration
├── Build pipeline (Windows/Mac/Linux)
└── Distribution scripts

Phase 6: Polish
├── Tests (unit, integration, e2e)
├── Docker/K8s deployment configs
├── CI/CD pipelines
└── Documentation
```

---

## 9. Quick Reference

### Where to Put Code

| What | Where |
|------|-------|
| DB repository interface | `backend/framework/database/interfaces/` |
| DB implementation (Postgres) | `backend/framework/database/postgres/` |
| DB implementation (SQLite) | `backend/framework/database/sqlite/` |
| gRPC proto files | `backend/framework/grpc/proto/` |
| gRPC generated code | `backend/framework/grpc/generated/` |
| Pure business logic | `backend/core/` |
| Feature module (handler, service, repo interface) | `backend/modules/<feature>/` |
| HTTP/gRPC handler | `backend/modules/<feature>/handler.go` |
| Service entrypoint | `apps/<service>/main.go` |
| Environment config | `configs/environments/<env>.yaml` |
| Migration files | `backend/framework/database/migrations/` |
| Svelte component | `frontend/src/components/<category>/` |
| Svelte feature module | `frontend/src/modules/<feature>/` |
| TypeScript types | `frontend/src/types/` |
| AI model/pipeline | `services/python-ai/models/` |
| Dockerfile | `deployments/docker/` |
| K8s manifests | `deployments/kubernetes/` |
| Documentation | `docs/` |
| CLI tool | `tools/auractl.sh` |

### File Naming

| Language | Convention | Example |
|----------|-----------|---------|
| Go files | snake_case | `user_repository.go` |
| Proto files | snake_case | `market_service.proto` |
| Svelte files | PascalCase | `PriceChart.svelte` |
| TypeScript files | camelCase | `marketStore.ts` |
| Config files | kebab-case | `development.yaml` |
| SQL migrations | numeric prefix | `001_create_users.sql` |

---

> **Remember:** Clean architecture is your competitive advantage. A well-structured codebase that's easy to navigate, test, and modify is what separates senior-level projects from the rest. Every minute spent on structure pays back tenfold in maintainability.
