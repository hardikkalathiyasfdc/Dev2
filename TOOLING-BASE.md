# Tooling Base Branch

`tooling/skills-base` carries **only** the repo-agnostic automation that follows every environment:

```
.github/            # instructions + skills + hooks
scripts/pmd/        # PMD PowerShell scripts only (no Apex probes)
package.json        # minimal: pmd scripts + husky/lint-staged for the hook
```

It is intentionally **orphan** (no shared history with `main`, no `force-app/`), so merging it into any environment repo never pulls in another org's metadata or Apex.

## Use it in any environment repo (Dev1, Dev2, Test, scratch)

```powershell
git remote add tooling https://github.com/hardikkalathiyasfdc/Dev2.git
git fetch tooling
git merge --allow-unrelated-histories tooling/tooling/skills-base
```

From then on, `git push` triggers the same PMD hook and the same skills regardless of which Salesforce org you're pointing at. When the base branch gets new skills/fixes: `git pull tooling tooling/skills-base`.

`TOOLING-BASE.md` itself stays on `main` only — it's not part of the base branch.
