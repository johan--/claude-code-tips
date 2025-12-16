---
name: notify
description: Send a macOS notification to alert the user. Use when the user asks to be notified when a task is done, or says "notify me when done", "let me know when finished", etc.
---

# Send Notification

Send a macOS notification that brings focus to the correct Terminal tab when clicked.

## Usage

**Important:** Use `source` to run the script (required for correct terminal tab detection):

```bash
source ~/.claude/scripts/notify-complete.sh "Your message here"
```

## Example messages

- "Task complete"
- "Build finished"
- "Tests passed"
- "Ready for review"

Keep the message short and descriptive of what was accomplished.
