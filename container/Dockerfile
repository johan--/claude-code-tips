# Claude Code Container with Gemini CLI fallback
# For running risky long-running agentic tasks in isolation
#
# Build:
#   docker build -t claude-code-container -f Dockerfile .
#
# Run:
#   docker run -it claude-code-container
#
# After starting, you need to manually authenticate:
#   1. Run `claude` and complete Anthropic login
#   2. Run `gemini` and complete Google login

FROM node:20-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y \
    tmux \
    jq \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code 2.0.57 (specific version for patching) and Gemini CLI
# Must be done as root for global npm install
RUN npm install -g @anthropic-ai/claude-code@2.0.57 @google/gemini-cli

# Clone the claude-code-tips repo
RUN git clone https://github.com/ykdojo/claude-code-tips.git /tmp/claude-code-tips

# Apply patches using the cloned repo (must be done as root)
RUN CLI_PATH=/usr/local/lib/node_modules/@anthropic-ai/claude-code/cli.js && \
    cp "$CLI_PATH" "$CLI_PATH.backup" && \
    node /tmp/claude-code-tips/system-prompt/2.0.57/patch-cli.js "$CLI_PATH"

# Create claude user (don't run as root)
RUN useradd -m -s /bin/bash claude

# Set up directories and copy files from cloned repo
RUN mkdir -p /home/claude/.claude/scripts /home/claude/.claude/skills/reddit-fetch /home/claude/.gemini && \
    cp /tmp/claude-code-tips/skills/reddit-fetch/SKILL.md /home/claude/.claude/skills/reddit-fetch/SKILL.md && \
    cp /tmp/claude-code-tips/scripts/context-bar.sh /home/claude/.claude/scripts/context-bar.sh && \
    chmod +x /home/claude/.claude/scripts/context-bar.sh && \
    cp /tmp/claude-code-tips/container/setup.sh /home/claude/setup.sh && \
    chmod +x /home/claude/setup.sh && \
    chown -R claude:claude /home/claude && \
    rm -rf /tmp/claude-code-tips

USER claude
WORKDIR /home/claude

# Set up aliases for convenience
RUN echo "alias c='claude'" >> ~/.bashrc && \
    echo "alias g='gemini'" >> ~/.bashrc

# Set up status line in settings.json
RUN echo '{"statusLine":{"type":"command","command":"~/.claude/scripts/context-bar.sh"}}' > ~/.claude/settings.json

# Set up Gemini settings with model
RUN echo '{"security":{"auth":{"selectedType":"oauth-personal"}},"general":{"previewFeatures":true},"model":{"name":"gemini-3-pro-preview"}}' > ~/.gemini/settings.json

# Working directory for projects
WORKDIR /home/claude/workspace

# Run setup on container start
CMD ["/home/claude/setup.sh"]
