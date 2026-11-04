---
name: git-push-checks
description: "Use when: committing, staging, or pushing changes to git (git push, git commit, push changes, BRME commits, pre-push checks, PMD, static analysis, quality gate), or when PMD/scanner/eslint findings need fixing. Loads the repo commit/push policy plus the pre-push quality gate: runs PMD (sf scanner) on changed Apex and eslint on changed aura/lwc JS, AUTO-CORRECTS High/Moderate violations before pushing (and re-corrects any violations the PreToolUse hook reports after a push), then commits per task and pushes. DO NOT USE FOR: sf deploys to orgs (use sfdc-deploy-and-batch), Flosum promotion."
---

# Git Push Checks (commit → quality gate → push)

The quality companion to the git policy in `.github/copilot-instructions.md` (commit every task, push to Dev2 remote). Load this skill whenever a task ends in `git commit` / `git push`, or when the user asks to commit/push/organize commits.

## Environment facts (verified 2026-11-04)

- git is NOT on PATH: use `& "C:\Program Files\Git\cmd\git.exe" ...`.
- PMD runs via Salesforce Code Analyzer: `sf scanner run` (plugin `@salesforce/sfdx-scanner` v4.6.0). `sf code-analyzer` does NOT exist on this CLI (2.62.6). sf CLI must run **unsandboxed** (EPERM on `C:\`).
- First scanner run downloads PMD (~30-90s cold start). Batch ALL changed files into ONE `sf scanner run` — never loop per file.
- `node_modules` and `.husky` exist; lint-staged (prettier + eslint + related jest) runs on commit via husky.
- Scanner JSON: array of `{ engine, fileName, violations: [{ line, severity, normalizedSeverity (1=high,2=moderate,3=low), ruleName, category, message }] }`.

## Workflow

### 1. Inventory and group changes

- `git status --porcelain` + `git diff --stat`; group files into logical commits (one per instruction/task, per repo policy).
- If a change's origin is unclear, check `plans/`, repo memory, or `git log` before grouping — never batch unrelated tasks into one commit.
- Include untracked files (`git ls-files --others --exclude-standard`) — `git diff HEAD` misses them.

### 2. Run the quality gate on the changed files (BEFORE committing)

Collect changed files (working tree vs `HEAD`, plus unpushed `origin/main...HEAD` when pushing), then:

**Apex changed (`.cls` / `.trigger` under force-app):**
```powershell
sf scanner run --engine pmd --normalize-severity --format table `
  --target "force-app/main/default/classes/Foo.cls" --target "force-app/main/default/classes/Bar.cls"
```

**aura/lwc JS changed:**
```powershell
npx eslint <changed js files>
```

**LWC changed:** also run related jest: `npx sfdx-lwc-jest -- --bail --findRelatedTests --passWithNoTests`.

### 3. Auto-correct PMD/eslint findings (user's standing instruction: \"warn and try to fix\", extended 2026-11-04: \"the session should auto correct the feedback from the salesforce PMD checks\")

When the quality gate (step 2) or the PreToolUse hook reports violations, correct them in-session — do NOT just report and move on. Fix-verify loop:

1. **Triage** the findings:
   - **Severity 1 (High) + 2 (Moderate) PMD, and eslint errors**: MUST attempt a fix.
   - **Severity 3 (Low)**: fix only trivial ones in touched code (ApexDoc on new methods, naming, brace style). Never mass-fix legacy noise (NotificationService alone has 65 Low).
   - Only fix violations on lines the current task actually touched. Pre-existing findings on untouched code: list them and ask — do not silently rewrite someone else's in-progress work.
2. **Apply focused fixes** with edit tools. Common PMD auto-fixes in this repo:
   - `FormalParameterNamingConventions` → rename param to `[a-z][a-zA-Z0-9]*` (e.g. `BC` → `bc`).
   - `OneDeclarationPerLine` → split `Integer a, b;` into two statements.
   - `EmptyCatchBlock` → add a comment or `BBApps_ErrorHandler.logErrors(ex, ...)` per the class's pattern.
   - `DML in loop` (`OperationWithLimitsInLoop`) → collect records, single DML outside the loop.
   - `ApexDoc` missing `@description` → add it on new/changed public/global members.
   - eslint errors → fix per rule (`no-unused-vars`, quotes, etc.); `npx eslint --fix <file>` handles the auto-fixable ones.
3. **Re-run the gate on the fixed files** (`sf scanner run` / `npx eslint` again) to confirm the findings cleared and no new ones appeared. If a fix needs behavior changes (complexity, unused code with side effects, risky refactor) — STOP, don't guess: show the user the finding + proposed fix and ask.
4. **Then commit per task and push** (step 4). If the hook still reports High/Moderate findings on touched files after the push, treat that as the next iteration of this loop — fix and follow-up commit — before calling the task done.

### 4. Commit per task, then push

- Subject `BRME-XXXX: <summary>` (or short description when no ticket); body = WHY + the user's instruction, compose it yourself. Components one per line (see sfdc-deploy-and-batch §12).
- Push to `https://github.com/hardikkalathiyasfdc/Dev2` branch `main` without asking (dev2/dev2Current only; other orgs → ask for repo URL first).

### 5. The hook is the safety net

- `.github/hooks/pre-push-quality.json` + `scripts/pre-push-quality.js` fire PreToolUse on every `git push` (detects `git push`, `& "...git.exe" push`, `$g push origin`). It re-runs PMD (changed Apex) + eslint (changed aura/lwc JS) and returns a **warn-only** `systemMessage` with violation counts and the top High/Moderate findings. The push is never blocked.
- If the hook reports violations after a push, acknowledge them in your summary and fix per step 3 in a follow-up commit.
- **Escape hatch**: include `SKIP_QUALITY` in the push command when the user explicitly says to skip checks for that push. Honor it for that push only.

## Anti-patterns

- Running `sf scanner run` once per file (cold JVM each time — batch targets).
- Blocking the push on violations (user chose warn-and-fix, not hard gate).
- Mass-fixing Low-severity/legacy findings unrelated to the task.
- Trusting `git status` alone for "changed files" — unpushed committed work only shows via `origin/main...HEAD`.
- Using `sf code-analyzer` (not installed on this CLI) or PMD standalone (not installed) — `sf scanner run --engine pmd` is the only working PMD path here.
