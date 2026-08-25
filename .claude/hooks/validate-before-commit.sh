#!/bin/bash
# Runs validation (type-check + lint + test) before git commit commands.
# Blocks the commit if validation fails.

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Only intercept git commit commands
if [[ ! "$COMMAND" =~ git[[:space:]]+commit ]]; then
  exit 0
fi

# Format code and re-stage any changes
pnpm run format 2>&1
git add -u 2>/dev/null

# Run the full validation suite
if ! pnpm run validate 2>&1; then
  echo "Validation failed. Fix errors before committing." >&2
  exit 2
fi

exit 0
