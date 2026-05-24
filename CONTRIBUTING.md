# Contributing

## Before You Start

1. Read [project.md](project.md) — understand the project scope
2. Read [AGENTS.md](AGENTS.md) — understand architecture conventions
3. Check the [ARCHITECTURE.md](ARCHITECTURE.md) for system design

## Development Workflow

1. Pick a feature from the project spec
2. Create a branch: `git checkout -b feature/your-feature`
3. Write interfaces first, then implementations
4. Add tests
5. Run `make test`
6. Push and open a PR

## Code Style

- Go: Follow standard `gofmt` conventions
- Svelte: PascalCase components, camelCase stores/functions
- Proto: snake_case for fields

## Architecture Rules

- Business logic goes in `backend/core/`
- Infrastructure goes in `backend/framework/`
- Feature glue goes in `backend/modules/`
- Entrypoints go in `apps/`
- Never import a module from another module
