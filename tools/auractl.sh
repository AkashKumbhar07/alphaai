#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────
#  AuraMind Developer Toolkit
#  Portable entry point for anyone cloning the repo
# ──────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

print_banner() {
  clear
  echo -e "${CYAN}"
  echo '  ╔══════════════════════════════════════╗'
  echo '  ║        AuraMind Developer Toolkit    ║'
  echo '  ╚══════════════════════════════════════╝'
  echo -e "${NC}"
}

check_deps() {
  local missing=()
  command -v go  >/dev/null 2>&1 || missing+=("go")
  command -v node >/dev/null 2>&1 || missing+=("node")
  command -v npm  >/dev/null 2>&1 || missing+=("npm")

  if [ ${#missing[@]} -gt 0 ]; then
    echo -e "${RED}Missing dependencies: ${missing[*]}${NC}"
    echo "Install them and try again."
    exit 1
  fi
}

print_menu() {
  echo -e "${BOLD}Select an option:${NC}"
  echo ""
  echo "  1)  Run Desktop App (Wails)"
  echo "  2)  Run All Backend Services"
  echo "  3)  Run AI Service (Python)"
  echo "  4)  Run Full Stack"
  echo "  5)  Build Windows .exe"
  echo "  6)  Build Mac .dmg"
  echo "  7)  Build Linux .AppImage"
  echo "  8)  Generate gRPC Code"
  echo "  9)  Run DB Migrations"
  echo " 10)  Seed Database"
  echo " 11)  Run All Tests"
  echo " 12)  Docker Build"
  echo " 13)  Kubernetes Deploy"
  echo " 14)  Clean Build"
  echo " 15)  Install All Dependencies"
  echo " 16)  Setup Dev Environment"
  echo "  0)  Exit"
  echo ""
  echo -n "Choice [0-16]: "
}

run_desktop() {
  echo -e "${GREEN}→ Running Desktop App...${NC}"
  cd "$PROJECT_ROOT/apps/desktop"
  if [ -f "main.go" ]; then
    wails dev
  else
    echo -e "${YELLOW}Desktop app not scaffolded yet. Run 'wails init' first.${NC}"
  fi
}

run_backend() {
  echo -e "${GREEN}→ Running Backend Services...${NC}"
  cd "$PROJECT_ROOT/backend"
  go run ./cmd/api &
  go run ./cmd/market &
  wait
}

run_ai() {
  echo -e "${GREEN}→ Running AI Service (Python)...${NC}"
  cd "$PROJECT_ROOT/services/python-ai"
  if [ -f "requirements.txt" ]; then
    uvicorn app.main:app --reload --port 8000
  else
    echo -e "${YELLOW}AI service not scaffolded yet.${NC}"
  fi
}

build_windows() {
  echo -e "${GREEN}→ Building Windows .exe...${NC}"
  cd "$PROJECT_ROOT/apps/desktop"
  GOOS=windows GOARCH=amd64 wails build -o "../../build/windows/AuraMind.exe"
  echo -e "${GREEN}✓ Build complete: build/windows/AuraMind.exe${NC}"
}

build_mac() {
  echo -e "${GREEN}→ Building Mac .dmg...${NC}"
  cd "$PROJECT_ROOT/apps/desktop"
  GOOS=darwin GOARCH=amd64 wails build -o "../../build/mac/AuraMind.dmg"
  echo -e "${GREEN}✓ Build complete: build/mac/AuraMind.dmg${NC}"
}

build_linux() {
  echo -e "${GREEN}→ Building Linux .AppImage...${NC}"
  cd "$PROJECT_ROOT/apps/desktop"
  GOOS=linux GOARCH=amd64 wails build -o "../../build/linux/AuraMind.AppImage"
  echo -e "${GREEN}✓ Build complete: build/linux/AuraMind.AppImage${NC}"
}

gen_proto() {
  echo -e "${GREEN}→ Generating gRPC Code...${NC}"
  cd "$PROJECT_ROOT/backend"
  bash scripts/generate-proto.sh
}

run_migrations() {
  echo -e "${GREEN}→ Running DB Migrations...${NC}"
  cd "$PROJECT_ROOT/backend"
  go run ./cmd/migrate
}

seed_db() {
  echo -e "${GREEN}→ Seeding Database...${NC}"
  cd "$PROJECT_ROOT/backend"
  go run ./cmd/seed
}

run_tests() {
  echo -e "${GREEN}→ Running All Tests...${NC}"
  cd "$PROJECT_ROOT/backend"
  go test ./... -v -count=1
}

docker_build() {
  echo -e "${GREEN}→ Docker Build...${NC}"
  cd "$PROJECT_ROOT"
  docker compose build
}

k8s_deploy() {
  echo -e "${GREEN}→ Kubernetes Deploy...${NC}"
  cd "$PROJECT_ROOT/deployments/kubernetes"
  kubectl apply -f .
}

clean_build() {
  echo -e "${YELLOW}→ Cleaning build artifacts...${NC}"
  rm -rf "$PROJECT_ROOT/build/windows/"* "$PROJECT_ROOT/build/mac/"* "$PROJECT_ROOT/build/linux/"*
  rm -rf "$PROJECT_ROOT/frontend/node_modules/.vite"
  echo -e "${GREEN}✓ Clean complete${NC}"
}

install_deps() {
  echo -e "${GREEN}→ Installing Go dependencies...${NC}"
  cd "$PROJECT_ROOT/backend"
  go mod tidy

  echo -e "${GREEN}→ Installing Node dependencies...${NC}"
  cd "$PROJECT_ROOT/frontend"
  if [ -f "package.json" ]; then
    npm install
  else
    echo -e "${YELLOW}Frontend not scaffolded yet.${NC}"
  fi

  echo -e "${GREEN}→ Installing Python dependencies...${NC}"
  cd "$PROJECT_ROOT/services/python-ai"
  if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
  fi
}

setup_env() {
  echo -e "${GREEN}→ Setting up development environment...${NC}"

  # Check prerequisites
  echo "  • Checking Go... $(go version 2>/dev/null || echo 'NOT FOUND')"
  echo "  • Checking Node... $(node --version 2>/dev/null || echo 'NOT FOUND')"
  echo "  • Checking npm... $(npm --version 2>/dev/null || echo 'NOT FOUND')"

  # Install Wails CLI
  if ! command -v wails &>/dev/null; then
    echo "  • Installing Wails CLI..."
    go install github.com/wailsapp/wails/v2/cmd/wails@latest
  else
    echo "  • Wails CLI already installed"
  fi

  # Setup git hooks
  if [ -d "$PROJECT_ROOT/.git" ]; then
    echo "  • Git hooks directory exists"
  fi

  # Copy default env config
  if [ ! -f "$PROJECT_ROOT/.env" ]; then
    cp "$PROJECT_ROOT/configs/environments/development.yaml" "$PROJECT_ROOT/.env" 2>/dev/null || true
  fi

  # Install all dependencies
  install_deps

  echo -e "${GREEN}✓ Development environment ready${NC}"
}

# ──────────────────────────────────────────────
#  Main
# ──────────────────────────────────────────────

check_deps

while true; do
  print_banner
  print_menu
  read -r choice

  case "$choice" in
    1)  run_desktop ;;
    2)  run_backend ;;
    3)  run_ai ;;
    4)  run_desktop ;;
    5)  build_windows ;;
    6)  build_mac ;;
    7)  build_linux ;;
    8)  gen_proto ;;
    9)  run_migrations ;;
    10) seed_db ;;
    11) run_tests ;;
    12) docker_build ;;
    13) k8s_deploy ;;
    14) clean_build ;;
    15) install_deps ;;
    16) setup_env ;;
    0)  echo -e "${GREEN}Goodbye!${NC}"; exit 0 ;;
    *)  echo -e "${RED}Invalid choice.${NC}"; sleep 1 ;;
  esac

  echo ""
  echo -n "Press Enter to continue..."
  read -r
done
