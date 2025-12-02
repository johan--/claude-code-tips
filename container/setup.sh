#!/bin/bash
# Setup script for Claude Code container

set -e

echo "Claude Code Container"
echo "====================="
echo ""
echo "All files are pre-installed. Ready to use!"
echo ""
echo "Next steps:"
echo "  1. Run 'claude' and authenticate with Anthropic"
echo "  2. Run 'gemini' and authenticate with Google"
echo ""
echo "Gemini is configured to use: gemini-3-pro-preview"
echo ""

# Start interactive shell
exec /bin/bash
