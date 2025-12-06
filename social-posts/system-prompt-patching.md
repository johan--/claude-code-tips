# Cutting Claude Code's System Prompt in Half to Save Tokens

Claude Code's system prompt and tool definitions take up about 18k tokens (~9% of your 200k context) before you even start working. I created a patch system that reduces this to about 10k tokens - saving around 7,300 tokens (41% of the static overhead, ~50% of the overall overhead).

| Component | Before | After | Savings |
|-----------|--------|-------|---------|
| System prompt | 2.9k | 2.0k | 900 tokens |
| System tools | 14.7k | 8.3k | 6,400 tokens |
| **Static total** | **~18k** | **~10k** | **~7,300 tokens (41%)** |
| Allowed tools list | ~2.5-3.5k | 0 | ~2.5-3.5k tokens |
| **Total** | **~21k** | **~10k** | **~10-11k tokens (~50%)** |

The allowed tools list is dynamic context - it grows as you approve more bash commands. With 70+ approved commands, mine was eating up 2,500-3,500 tokens. The patch removes this list entirely.

Here's what `/context` looks like before and after patching:

| Unpatched (~18k, 9%) | Patched (~10k, 5%) |
|---------------------|-------------------|
| ![Unpatched context](https://github.com/ykdojo/claude-code-tips/blob/main/system-prompt/2.0.59/context-unpatched.png?raw=true) | ![Patched context](https://github.com/ykdojo/claude-code-tips/blob/main/system-prompt/2.0.59/context-patched.png?raw=true) |

The patches work by trimming verbose examples and redundant text from the minified CLI bundle while keeping all the essential instructions. For example, the TodoWrite examples go from 6KB to 0.4KB, and the Bash tool description drops from 3.7KB to 0.6KB.

I've tested this extensively and it works well. It feels more raw - more powerful, but maybe a little less regulated, which makes sense because the system instruction is shorter. It feels more like a pro tool when you use it this way. I really enjoy starting with lower context because you have more room before it fills up, which gives you the option to continue conversations a bit longer. That's definitely the best part of this strategy.

For the patch scripts and full details on what gets trimmed, feel free to check [this](https://github.com/ykdojo/claude-code-tips/tree/main/system-prompt).

**Requirements**: These patches require npm installation (`npm install -g @anthropic-ai/claude-code`). The patching works by modifying the JavaScript bundle (`cli.js`) - other installation methods may produce compiled binaries that can't be patched this way.

Originally posted in [this repo](https://github.com/ykdojo/claude-code-tips/tree/main?tab=readme-ov-file#tip-13-slim-down-the-system-prompt).
