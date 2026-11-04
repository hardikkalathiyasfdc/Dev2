---
name: git-push-checks
description: "Use when: committing, staging, or pushing changes to git (git push, git commit, push changes, BRME commits, pre-push checks, PMD, static analysis, quality gate). Loads the repo commit/push policy plus the pre-push quality gate: runs PMD (sf scanner) on changed Apex and eslint on changed aura/lwc JS, fixes High/Moderate violations before pushing, then commits per task and pushes. A warn-only PreToolUse hook re-checks on every git push and surfaces remaining violations. DO NOT USE FOR: sf deploys to orgs (use sfdc-deploy-and-batch), Flosum promotion."
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

### 3. Warn and fix (user's standing instruction: "warn and try to fix")

- **Severity 1 (High) and 2 (Moderate) PMD violations + eslint errors**: attempt a safe, focused fix before committing — only for violations on lines the task actually touched. If a fix is risky, large, or touches pre-existing legacy issues, do NOT rewrite: list the violations to the user, say push proceeds warn-only, and ask if they want them addressed.
- **Severity 3 (Low)**: report counts; fix only trivial ones in touched code. Legacy classes are noisy (NotificationService alone has 65 Low) — never mass-fix.
- After fixing, re-run the gate once to confirm, then commit.

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
