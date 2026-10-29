# Copilot instructions for this workspace

Salesforce DX project. See `.github/skills/sfdc-deploy-and-batch/SKILL.md` for Apex batch/callout and sf CLI deploy lessons — read it before editing batch/queueable Apex or running `sf` deploys.

## Git: commit every change (default behavior, every task)

Goal: every change must be traceable in git history to the instruction that caused it (e.g. "which of the 20 changes on Oct 23 fixed what").

- **git executable**: not on PATH in the terminal. Use `& "C:\Program Files\Git\cmd\git.exe" ...` for all git commands.
- **Remote / push**: this workspace's remote is **https://github.com/hardikkalathiyasfdc/Dev2** (branch `main`). This is the repo for **dev2 / dev2Current** work — commit AND push here automatically for any dev2 task without asking. Pushing here does NOT require explicit per-task permission (the "never push" rule below is overridden for this dev2 remote only).
  - **Other orgs (e.g. Dev1) must NOT reuse this repo.** If the current `target-org` is not dev2/dev2Current, STOP and ask the user to create/provide a new repo URL for that org before pushing — each org track gets its own repo.
- **Repo check first**: if `git status` fails or there is no `.git`, STOP and tell the user — offer to `git init` before making any file changes. Do not make untracked edits.
- **Before starting a task**: if the working tree is dirty, commit (or, if the changes belong to another unfinished task, ask the user first) so the new task starts from a clean baseline and its diff is attributable.
- **After completing a task**: stage only the files changed for that task and commit. One commit per instruction/task — do not batch multiple unrelated tasks into one commit.
- **Commit message format** (compose it yourself from session context — NEVER ask the user for the message):
  - Subject: `BRME-XXXX: <short summary>` (use the ticket folder in play; if no ticket, a short description of the request).
  - Body: a detailed explanation of WHY the change was made and WHAT the user's instruction was (verbatim or close summary from the session), so `git log` alone answers "what was fixed due to which instruction".
- Never amend, rebase, or commit unrelated/pre-existing changes unless the user explicitly asks.
- If the user says to skip the commit for a change, honor that for that change only.

## Sandbox deploys: detailed message on every deploy (default behavior)

Every `sf project deploy start` to a sandbox org must carry a detailed message so the org's deploy history (`DeployRequest`) is self-explanatory.

- Compose the message yourself from session context — NEVER ask the user for it.
- Include it on the command: `sf project deploy start --description "<message>" ...` so it lands on the `DeployRequest` record that the org-side verification already queries.
- Message must state:
  - **What** changed: ticket + components being deployed (e.g. `BRME-7045: BudgetApprovalController.cls + DIT field set`).
  - **Why**: the user's instruction that caused it, verbatim or close summary (e.g. "per request: reset approval status and notify owner when a budget is sent back for revisions").
  - **Session context** when relevant: prior attempts/rollbacks, related test classes run, or the validation step it belongs to.
- Keep it one line but information-dense; the commit body holds the longer detail, and the two should match in substance.
- Applies to dry-run/validate-only deploys too — label them (e.g. prefix `VALIDATE:`) so history distinguishes validation from real deploys.

## Sandboxes: Dev1 / Dev2 are separate tracks — never merge across them

- The user works on multiple sandboxes (e.g. **Dev1**, **Dev2**). Each is its own line of work — changes for one must NOT be merged, deployed, or carried into the other.
- **Determine the current sandbox yourself, never ask**: read the default target org via `sf config get target-org` (or the `target-org` entry in `.sf/config.json` / `.sfdx/sfdx-config.json`). Use that org name/alias (e.g. `Dev1`, `Dev2`) as the context for everything that follows.
- Prefix deploy descriptions and commit context with the sandbox when it isn't obvious from the ticket, so history shows which sandbox a change belonged to (e.g. `Dev2 BRME-7045: ...`).
- If no default org is set, tell the user and stop rather than guessing which sandbox to use.

## Environment notes

- sf CLI and terminal commands that hit `C:\` must run unsandboxed (sandbox gives `EPERM lstat 'C:\'`; the packaged MSIX pwsh also cannot launch inside the sandbox).
