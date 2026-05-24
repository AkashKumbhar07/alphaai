#!/usr/bin/env bash
set -euo pipefail

PROTO_DIR="$(cd "$(dirname "$0")/../framework/grpc/proto" && pwd)"
OUT_DIR="$(cd "$(dirname "$0")/../framework/grpc/generated" && pwd)"

echo "Generating gRPC code from proto files..."
echo "  Proto dir: $PROTO_DIR"
echo "  Output dir: $OUT_DIR"

mkdir -p "$OUT_DIR"

protoc \
  --proto_path="$PROTO_DIR" \
  --go_out="$OUT_DIR" \
  --go-grpc_out="$OUT_DIR" \
  "$PROTO_DIR"/*.proto

echo "Done."
