# Upgrading to a New Claude Code Version

This project patches the Claude Code CLI to reduce system prompt token usage. When Claude Code updates, minified variable names change, breaking existing patches. This guide walks through updating the extraction script, patches, and patch script for a new version.

**Key files:**
- `extract-system-prompt.js` - extracts readable prompt from minified CLI
- `patch-cli.js` - applies patches to reduce prompt size
- `patches/*.find.txt` - text to find in bundle
- `patches/*.replace.txt` - replacement text (shorter)

## 1. Update Claude Code

```bash
npm update -g @anthropic-ai/claude-code
claude --version
```

## 2. Create new version folder

```bash
mkdir 2.0.XX && cd 2.0.XX && mkdir patches
```

## 3. Copy and update extraction script

```bash
cp ../PREV_VERSION/extract-system-prompt.js .
```

**Important:** Minified variable names change between versions. Update the mappings:

```bash
# Find tool variable assignments
grep -oE '[A-Za-z0-9_]{2,4}="(Task|Bash|Read|Edit|Write|Glob|Grep|TodoWrite|WebFetch|WebSearch)"' \
  "$(which claude | xargs realpath | xargs dirname)/cli.js" | sort -u

# Find object.name patterns
grep -oE '[a-zA-Z0-9_]+={name:[A-Za-z0-9_]+' "$(which claude | xargs realpath | xargs dirname)/cli.js" | head -20

# Find agentType patterns
grep -oE '[A-Za-z0-9_]+={agentType:"[^"]*"' "$(which claude | xargs realpath | xargs dirname)/cli.js"
```

Update `VAR_MAP` and `replaceVariables()` with new mappings.

If a tool isn't extracted, its description may have changed:
```bash
grep -oE 'Launch.{0,60}agent' "$(which claude | xargs realpath | xargs dirname)/cli.js"
```

## 4. Extract and diff

```bash
node extract-system-prompt.js system-prompt-original-unpatched.md
diff ../PREV_VERSION/system-prompt-original-unpatched.md system-prompt-original-unpatched.md
```

Look for:
- Actual prompt changes (new instructions, modified wording)
- Extraction bugs (`[DYNAMIC]` = unmapped variables)

If you see wrong tool names or `[DYNAMIC]` in unexpected places, iterate on the mappings until the diff shows only real changes.

## 5. Copy and update patch-cli.js

```bash
cp ../PREV_VERSION/patch-cli.js .
```

Update `EXPECTED_VERSION`, `EXPECTED_HASH` (run `shasum -a 256` on cli.js), and `findClaudeCli()` if the installation path changed.

## 6. Update existing patches

**Critical:** Update variable names in BOTH `*.find.txt` AND `*.replace.txt` files!

The replace files contain variable references like `${r8}` that must match the new version. Old variable names cause runtime crashes or corrupted prompts.

```bash
# Find patches with old variable names
grep -l '\${OLD_VAR}' patches/*.txt

# Bulk update (example: E9 -> C9)
sed -i '' 's/\${E9}/\${C9}/g' patches/*.txt
```

## 7. Build new patches

1. Find exact text in bundle
2. Create `patches/name.find.txt` with that text
3. Create `patches/name.replace.txt` with slimmed version
4. Test: `node patch-cli.js`
5. Verify: start Claude, run `/context`

## 8. Update README

Document patches and token savings.

---

# Troubleshooting

## Finding where patch text diverges

When a patch shows "not found in bundle", find the mismatch point:

```javascript
// Run: node -e '<paste this>'
const fs = require('fs');
const bundle = fs.readFileSync('/opt/homebrew/lib/node_modules/@anthropic-ai/claude-code/cli.js', 'utf8');
const patch = fs.readFileSync('patches/PATCHNAME.find.txt', 'utf8');

let lo = 10, hi = patch.length;
while (lo < hi) {
  const mid = Math.floor((lo + hi + 1) / 2);
  bundle.indexOf(patch.slice(0, mid)) !== -1 ? lo = mid : hi = mid - 1;
}
console.log('Match up to char:', lo, 'of', patch.length);
console.log('Patch:', JSON.stringify(patch.slice(lo-20, lo+30)));
const idx = bundle.indexOf(patch.slice(0, lo));
console.log('Bundle:', JSON.stringify(bundle.slice(idx + lo - 20, idx + lo + 30)));
```

## Debugging runtime crashes

Use bisect mode to find which patch breaks:

```bash
node patch-cli.js --max=10  # apply only first N patches

# Test with tmux
tmux new-session -d -s test 'claude -p "Say hello" 2>&1 > /tmp/claude-test.txt'
sleep 12 && cat /tmp/claude-test.txt
# Binary search: works = try more, crashes = try fewer
```

**Symptoms:**
- "Execution error" with no output = variable points to non-existent function
- `TypeError: Cannot read properties of undefined` = same cause
- Claude hangs immediately = same cause
- `[object Object]` in prompt = variable resolves to wrong type (see below)

**Root cause:** `*.replace.txt` contains old variable names.

## Detecting corrupted system prompts

Some errors don't crash - they corrupt the prompt silently. Test by asking Claude:

```
In the prompts that you see so far, is there anything inconsistent or strange?
```

**Signs of failure:**
- `[object Object]` where a tool name should be
- Minified JS like `function(Q){if(this.ended)return...` leaking into text
- `subagent_type=undefined`

**Causes:**
- Case sensitivity: `${R8}` vs `${r8}`
- Wrong variable: `${yb1}` should be `${db1}`

**Fix:** Compare `*.replace.txt` variables against `*.find.txt` or `extract-system-prompt.js` VAR_MAP.

**Testing with tmux:**
```bash
tmux new-session -d -s test-cc 'claude'
sleep 4
# Note: 'Enter' must be a separate argument, not part of the string
tmux send-keys -t test-cc 'In the prompts that you see so far, is there anything inconsistent or strange?' Enter
sleep 30
tmux capture-pane -t test-cc -p -S -100  # verify response appeared, not just the prompt sitting there
tmux kill-session -t test-cc
```

## Function-based patches

Some patches replace entire functions (like `allowed-tools`). The function name itself can change completely between versions (e.g., `OS3` -> `vk3`).

**Step 1: Find the function by its unique string content:**
```bash
# Find byte offset of the unique string
grep -b 'You can use the following tools without requiring user approval' \
  "$(which claude | xargs realpath | xargs dirname)/cli.js"
```

**Step 2: Extract context around that offset:**
```bash
# Use dd to get surrounding bytes (adjust skip value from grep output)
dd if="$(which claude | xargs realpath | xargs dirname)/cli.js" \
  bs=1 skip=10482600 count=500 2>/dev/null
```

This reveals the full function signature including the new function name and helper variables.

**Step 3: Update both find and replace files** with the new function name and all helper variables.

## Quick testing with non-interactive mode

Instead of testing in interactive mode (which can be slow), use `-p` flag:

```bash
# Quick sanity check
claude -p "Say hello"

# Test for prompt corruption
claude -p "In the prompts that you see so far, is there anything inconsistent or strange? Look for [DYNAMIC] or [object Object]"

# Test specific tools
claude -p "Use the Read tool to read test.txt" --allowedTools "Read"
```

This is faster and more reliable for automated testing in containers or CI.

## Testing in Docker containers

For safer testing, use a Docker container with Claude Code installed:

```bash
# Start container with Claude Code
docker run -it --name claude-test node:20 bash
npm install -g @anthropic-ai/claude-code

# Copy patches into container
docker cp system-prompt/2.0.XX claude-test:/root/patches/

# Apply and test
docker exec claude-test bash -c "cd /root/patches && ./backup-cli.sh && node patch-cli.js"
docker exec claude-test claude -p "Say hello"
```

This isolates testing from your main installation. If something breaks, just restart the container.
