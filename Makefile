.PHONY: run-desktop run-backend run-ai build-windows build-mac build-linux proto migrate seed test docker-up docker-build clean setup

# ──────────────────────────────────────────────
#  Development
# ──────────────────────────────────────────────

run-desktop:
	cd apps/desktop && wails dev

run-backend:
	cd backend && go run ./cmd/api &
	cd backend && go run ./cmd/market &
	wait

run-ai:
	cd services/python-ai && uvicorn app.main:app --reload --port 8000

# ──────────────────────────────────────────────
#  Build
# ──────────────────────────────────────────────

build-windows:
	cd apps/desktop && GOOS=windows GOARCH=amd64 wails build -o ../../build/windows/AuraMind.exe

build-mac:
	cd apps/desktop && GOOS=darwin GOARCH=amd64 wails build -o ../../build/mac/AuraMind.dmg

build-linux:
	cd apps/desktop && GOOS=linux GOARCH=amd64 wails build -o ../../build/linux/AuraMind.AppImage

# ──────────────────────────────────────────────
#  gRPC & Database
# ──────────────────────────────────────────────

proto:
	cd backend && bash scripts/generate-proto.sh

migrate:
	cd backend && go run ./cmd/migrate

seed:
	cd backend && go run ./cmd/seed

# ──────────────────────────────────────────────
#  Testing
# ──────────────────────────────────────────────

test:
	cd backend && go test ./... -v -count=1

# ──────────────────────────────────────────────
#  Docker
# ──────────────────────────────────────────────

docker-up:
	docker compose up -d

docker-build:
	docker compose build

# ──────────────────────────────────────────────
#  Utilities
# ──────────────────────────────────────────────

clean:
	rm -rf build/windows/* build/mac/* build/linux/*
	rm -rf frontend/node_modules/.vite

setup:
	@echo "Run 'bash tools/auractl.sh' and select option 16"
