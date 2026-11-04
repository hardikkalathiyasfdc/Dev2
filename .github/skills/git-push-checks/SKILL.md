---
name: git-push-checks
description: "Use when: committing, staging, or pushing changes to git (git push, git commit, push changes, BRME commits, pre-push checks, PMD, static analysis, quality gate), or when PMD/scanner/eslint findings need fixing. Loads the repo commit/push policy plus the pre-push quality gate: runs PMD (sf scanner) on changed Apex and eslint on changed aura/lwc JS, AUTO-CORRECTS High/Moderate violations before pushing (and re-corrects any violations the PreToolUse hook reports after a push), then commits per task and pushes. DO NOT USE FOR: sf deploys to orgs (use sfdc-deploy-and-batch), Flosum promotion."
---

# Git Push Checks (commit → quality gate → push)

The quality companion to the git policy in `.github/copilot-instructions.md` (commit every task, push to Dev2 remote). Load this skill whenever a task ends in `git commit` / `git push`, or when the user asks to commit/push/organize commits.

## Environment facts (verified 2026-11-04)

- **This repo is the tooling base.** `.github/` + `scripts/` also live on branch `tooling/skills-base`; merge that into any environment repo (Dev1/Dev2/Test/scratch) so the same skills and push hook follow you when you switch orgs. See `TOOLING-BASE.md`.
- git is NOT on PATH: use `& "C:\Program Files\Git\cmd\git.exe" ...`.
- PMD runs via **Salesforce Code Analyzer v5** (`sf code-analyzer run`, plugin `code-analyzer` 5.16.0 linked on npm-global CLI 2.150.6); the runner auto-falls back to **v4** (`sf scanner run`, `@salesforce/sfdx-scanner` 4.6.0) on environments without v5. `scripts/pmd/Invoke-PmdScan.ps1` resolves the right `sf` binary (PATH often shadows the newer npm-global CLI with `C:\Program Files\sf` 2.62.6). sf CLI must run **unsandboxed** (EPERM on `C:\`).
- v5 differences: no `--pmdconfig`/`--engine`/`--normalize-severity` — engine filter is `--rule-selector pmd`, custom rules live in `code-analyzer.yml` at repo root (auto-loaded; `config_root` must be absolute — the runner injects a temp overlay), severity is `severity` 1=Critical..5=Info (hook's sev≤2 gate unchanged), PMD bumped 7.5.0 → 7.26.0.
- First scanner run downloads PMD (~30-90s cold start). Batch ALL changed files into ONE run — never loop per file.
- `node_modules` and `.husky` exist; lint-staged (prettier + eslint + related jest) runs on commit via husky.
- Report JSON shapes: v5 `{ violations: [{ rule, severity, locations: [{ file, startLine }], primaryLocationIndex, message }] }`; v4 `[{ engine, fileName, violations: [{ line, normalizedSeverity, ruleName, message }] }]`. The hook parses both.

## Workflow

### 1. Inventory and group changes

- `git status --porcelain` + `git diff --stat`; group files into logical commits (one per instruction/task, per repo policy).
- If a change's origin is unclear, check `plans/`, repo memory, or `git log` before grouping — never batch unrelated tasks into one commit.
- Include untracked files (`git ls-files --others --exclude-standard`) — `git diff HEAD` misses them.

### 2. Run the quality gate on the changed files (BEFORE committing)

Collect changed files (working tree vs `HEAD`, plus unpushed `origin/main...HEAD` when pushing), then:

**Apex changed (`.cls` / `.trigger` under force-app):** use the shared runner (auto-picks `pmd/apex-ruleset.xml` when present, batches all files in one JVM):
```powershell
pwsh -File scripts/pmd/Scan-ApexChanged.ps1          # all changed Apex (staged+unstaged+untracked+unpushed)
pwsh -File scripts/pmd/Scan-ApexFile.ps1 -File force-app/main/default/classes/Foo.cls   # single file
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
- **Deployment context in the commit body**: any commit whose change was validated/deployed gets a `Deploy:` trailer — ticket, org alias, DeployRequest Id(s) + status (real + dry-run), tests run + pass/fail. And update `<BRME-XXXX>/README.md` "Post-deployment" at end of the ticket session (see sfdc-deploy-and-batch §13). `git log` + the ticket folder must be enough to reconstruct context later.
- **Push to the current environment's repo without asking.** Detect it: `git remote get-url origin` (each org track has its own repo — Dev2 pushes to `hardikkalathiyasfdc/Dev2`). If there is no `origin` or the org doesn't match the repo name, STOP and ask for the repo URL.

### 5. The hook is the safety net

- `.github/hooks/pre-push-quality.json` + `scripts/pre-push-quality.js` fire PreToolUse on every `git push` (detects `git push`, `& "...git.exe" push`, `$g push origin`). It re-runs PMD (changed Apex) + eslint (changed aura/lwc JS) and returns a **warn-only** `systemMessage` with violation counts and the top High/Moderate findings. The push is never blocked.
- If the hook reports violations after a push, acknowledge them in your summary and fix per step 3 in a follow-up commit.
- **Escape hatch**: include `SKIP_QUALITY` in the push command when the user explicitly says to skip checks for that push. Honor it for that push only.

## Anti-patterns

- Running PMD once per file (cold JVM each time — batch targets).
- Blocking the push on violations (user chose warn-and-fix, not hard gate).
- Mass-fixing Low-severity/legacy findings unrelated to the task.
- Trusting `git status` alone for "changed files" — unpushed committed work only shows via `origin/main...HEAD`.
- Assuming plain `sf` resolves to the v5 CLI — PATH may shadow it; always go through `scripts/pmd/Invoke-PmdScan.ps1` (it resolves the right binary and the v4/v5 command for you).
