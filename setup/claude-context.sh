#!/usr/bin/env bash
# Setup Claude Context (zilliztech) - vector search MCP
# Requires: OPENAI_API_KEY, MILVUS_ADDRESS (Zilliz Cloud endpoint), MILVUS_TOKEN

set -euo pipefail

if [[ -z "${OPENAI_API_KEY:-}" || -z "${MILVUS_ADDRESS:-}" || -z "${MILVUS_TOKEN:-}" ]]; then
  echo "Missing required env vars. Export before running:"
  echo "  export OPENAI_API_KEY=sk-..."
  echo "  export MILVUS_ADDRESS=https://in03-xxxxx.serverless.gcp-us-west1.cloud.zilliz.com"
  echo "  export MILVUS_TOKEN=your-zilliz-token"
  echo ""
  echo "Get free Zilliz Cloud account: https://cloud.zilliz.com/signup"
  echo "Get OpenAI API key: https://platform.openai.com/api-keys"
  exit 1
fi

claude mcp add claude-context \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  -e MILVUS_ADDRESS="$MILVUS_ADDRESS" \
  -e MILVUS_TOKEN="$MILVUS_TOKEN" \
  -- npx -y @zilliz/claude-context-mcp@latest

echo "Claude Context MCP added. Restart Claude Code to load."
echo "Verify: claude mcp list | grep claude-context"
