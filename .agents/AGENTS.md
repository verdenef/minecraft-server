# Project Agent Rules

## Anti-Hallucination Guardrails

1. **Verify Before Asserting**:
   - Never assume or guess file paths, directory structures, CLI flags, method signatures, or variable names.
   - Always inspect the target file or workspace directory using inspection tools (`view_file`, `list_dir`, `grep_search`) before stating facts or making code edits.

2. **Empirical Evidence Required**:
   - Base all diagnostic claims and technical explanations strictly on observable logs, error traces, or inspected source code.
   - If context or information is missing, state the uncertainty explicitly instead of filling in missing details with plausible guesses.

3. **Strict Code & Command Verification**:
   - Do not claim a feature or fix is working without running verification steps when available.
   - Always cross-reference API usage or CLI commands against official schemas, command help outputs, or existing repository patterns.
