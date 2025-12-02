# Claude Code Container

A Docker container for running risky, long-running agentic tasks in isolation. Includes Claude Code, Gemini CLI (as a fallback for blocked sites), and all the customizations from this repo.

## Why Use This

- **Isolation**: If something goes wrong, it's contained
- **Long-running tasks**: Leave it running without tying up your terminal
- **YOLO mode**: Auto-approve everything in a sandboxed environment
- **Reproducible setup**: Same config every time

## Quick Start

```bash
# Build the image (from the container directory, or anywhere with the Dockerfile)
docker build -t claude-code-container -f Dockerfile .

# Run
docker run -it claude-code-container
```

The Dockerfile pulls the latest `claude-code-tips` repo from GitHub during build, so no local files are needed.

## First-Time Authentication

After starting the container, you need to authenticate both CLIs manually:

### 1. Claude Code

```bash
claude
```

Follow the prompts to log in with your Anthropic account. This opens a browser URL - copy it to your host browser if needed.

### 2. Gemini CLI

```bash
gemini
```

Follow the prompts to log in with your Google account.

## What's Included

- **Claude Code 2.0.56** with system prompt patches applied (~39% token savings)
- **Gemini CLI** pre-configured with `gemini-3-pro-preview` model
- **tmux** for the reddit-fetch skill
- **Status bar** showing model, git status, and token usage
- **Skills** (reddit-fetch) built into the container

## Persisting Auth

To avoid re-authenticating Gemini every time, you can mount the credential directory:

```bash
docker run -it \
  -v ~/.gemini:/home/claude/.gemini \
  claude-code-container
```

Note: Claude Code credentials are stored in macOS Keychain, so you'll need to re-auth Claude each time (or use `ANTHROPIC_API_KEY` env var if you have one).

## Working with Projects

Mount your project directory:

```bash
docker run -it \
  -v /path/to/your/project:/home/claude/workspace \
  claude-code-container
```

Then `cd /home/claude/workspace` and start Claude Code there.

## Updating

To get the latest changes:

1. Rebuild the image: `docker build --no-cache -t claude-code-container -f Dockerfile .`
2. Run a new container

The `--no-cache` flag ensures it pulls the latest from GitHub.
