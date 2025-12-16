#!/bin/bash
# Notify when Claude Code finishes responding
# Receives JSON input via stdin with: session_id, transcript_path, cwd, permission_mode, etc.

INPUT=$(cat)

# Prevent infinite loops
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
    exit 0
fi

# Extract project name from cwd
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT_NAME=$(basename "$CWD")

# Extract last user message from transcript
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // ""')
LAST_USER_MSG=""
if [ -n "$TRANSCRIPT_PATH" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    # Get the last user text message (not tool results) from the JSONL transcript
    # Uses tail -r (macOS) to read file in reverse, then filter for user messages with string content
    LAST_USER_MSG=$(tail -r "$TRANSCRIPT_PATH" | jq -r 'select(.type == "user") | select(.message.content | type == "string") | .message.content' 2>/dev/null | head -1 | head -c 80)
fi

# Set title and message
TITLE="${PROJECT_NAME:-Claude Code}"
if [ -n "$LAST_USER_MSG" ]; then
    MESSAGE="$LAST_USER_MSG"
else
    MESSAGE="Claude needs your attention"
fi

# Get the Terminal window ID and tab index by matching the parent process's TTY
TTY="/dev/$(ps -p $PPID -o tty= 2>/dev/null | tr -d ' ')"
WINDOW_INFO=$(osascript -e "
tell application \"Terminal\"
    repeat with w in windows
        set tabIndex to 0
        repeat with t in tabs of w
            set tabIndex to tabIndex + 1
            if tty of t is \"$TTY\" then
                return (id of w as string) & \",\" & (tabIndex as string)
            end if
        end repeat
    end repeat
end tell" 2>/dev/null)

WINDOW_ID=$(echo "$WINDOW_INFO" | cut -d',' -f1)
TAB_INDEX=$(echo "$WINDOW_INFO" | cut -d',' -f2)

# Build command to activate the specific Terminal window and tab
if [ -n "$WINDOW_ID" ] && [ -n "$TAB_INDEX" ]; then
    ACTIVATE_SCRIPT="osascript -e 'tell application \"Terminal\"' -e 'activate' -e 'set frontmost of window id $WINDOW_ID to true' -e 'set selected tab of window id $WINDOW_ID to tab $TAB_INDEX of window id $WINDOW_ID' -e 'end tell'"
else
    # Fallback: just activate Terminal
    ACTIVATE_SCRIPT="osascript -e 'tell application \"Terminal\" to activate'"
fi

terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound default -execute "$ACTIVATE_SCRIPT"
